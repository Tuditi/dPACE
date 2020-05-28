pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;
/* Author: David De Troch
The goal of this contract is to implement the a tumbler that can be used for aggregated car sharing
providing an application specifici payment hub. This payment hub is able to provide anonimity between
car renter and driver.
Contract consists of three phases:

Phase 1: Deploy car, renter and tumbler
Phase 2: Booking and Payment of car
Phase 3: Withdraw Balance
*/
contract carSharing{

    //Renter Mappings
    mapping(address => uint)        renter_balance;
    mapping(address => uint)        renter_state;
    mapping(address => uint)        renter_start;
    mapping(address => address)     renter_links;
    mapping(address => bytes32)     renter_hashlock;
    mapping(address => bytes32)     renter_ppc;


    //Car Mappings
    mapping(address => uint)        car_balance;
    mapping(address => uint)        car_state;
    mapping(address => uint)        car_price;
    mapping(address => uint)        car_start;
    mapping(address => address)     car_owner;
    mapping(address => address)     car_links;
    mapping(address => bytes32)     car_hashlock;
    mapping(address => bytes32)     car_token;

    //Ring Message where instance (1 = ppc, 2 = hashlock, 3=fee, 4 = timestamp) specifies the content
    struct RingMessage{
        address destination;
        uint    instance;
        uint    content;
    }

    //Groupings of published signatures
    mapping(uint256 => bool)        keyImageUsed;

    //Constants
    uint    DEPOSIT                 = 5 ether;
    uint    PERIOD                  = 86400;
    address REGISTRATION_SERVICE    = address(0);

    //Events
    event E_deployRenter(address indexed, bytes32 ppc);
    event E_deployCar(address indexed, bytes32 details);
    event E_carAvailable(address indexed, bytes32 indexed token, bytes32 location, uint price);
    event E_carBooking(address indexed, bytes32 hashlock);
    event E_renterBooking(address indexed, bytes32 indexed hashlock, bytes32 indexed secretLink);
    event E_carPaid(address indexed, bytes32 indexed encryptedPreimage, bytes32 indexed newToken);
    event E_renterPaid(address indexed);
    event E_forcedEnd(address indexed, bytes32 indexed newToken);

    //Modifiers
    modifier checkDeposit(){
        require(msg.value >= DEPOSIT,'Not enough deposit to enter system');
        _;
    }
    modifier carAvailable(){
        require(car_state[msg.sender] == 1, 'Car is unavailable');
        _;
    }
    modifier renterAvailable(){
        require(renter_state[msg.sender] == 1, 'Renter is unavailable');
        _;
    }
    modifier carBooked(){
        require(car_state[msg.sender] == 2,'Car is not booked');
        _;
    }
    modifier renterBooked(){
        require(renter_state[msg.sender] == 2,'Renter is not booked');
        _;
    }
    modifier onlyCarOwner(address _car){
        require(car_owner[_car]==msg.sender, 'Only owner can view balance');
        _;
    }

    modifier unusedKeyImage(bytes32 _r, bytes32 _s, uint8 _v){
        require(!keyImageUsed[uint(keccak256(abi.encode(_v,_r,_s)))],"Key image already used!");
        _;
    }
    //Phase 1: renter and car are deployed as entities on the blockchain
    //Key
    function deployRenter(bytes32 _ppc, bytes32 _r, bytes32 _s, uint8 _v) public payable checkDeposit() unusedKeyImage(_r, _s, _v)
    {
        require(REGISTRATION_SERVICE == ecrecover(_ppc, _v, _r, _s), "No valid PPC_renter");
        keyImageUsed[uint(keccak256(abi.encode(_v,_r,_s)))] = true;

        renter_state[msg.sender] = 1;
        renter_balance[msg.sender] = msg.value;
        renter_ppc[msg.sender] = _ppc;
        emit E_deployRenter(msg.sender, _ppc);
    }

    function deployCar(address _address, bytes32 _details, uint _price) public payable checkDeposit()
    {
        car_balance[_address] = msg.value;
        car_owner[_address] = msg.sender;
        car_price[_address] = _price;
        emit E_deployCar(_address, _details);
    }
    
    function validateCar(bytes32 _token, bytes32 _location) public
    {
        require(car_owner[msg.sender] != address(0),'Car not yet deployed');
        require(car_state[msg.sender] == 0, 'Car not yet validated');
        car_state[msg.sender] = 1;
        emit E_carAvailable(msg.sender, _token, _location, car_price[msg.sender]);
    }

    //Phase 2: A booking is initiated
    function renterBooking(
        address     _car,
        bytes32     _secretLink,
        bytes32     _r,
        bytes32     _s,
        uint8       _v,
        RingMessage memory _message)
        public renterAvailable() unusedKeyImage(_r, _s, _v)
    {
        require(renter_balance[msg.sender] >= DEPOSIT, 'not enough deposit to start booking');
        require(_message.destination == msg.sender, 'Signature not for this receiver');
        require(isSignatureValid(_car, _message, _v, _r, _s),"Hashlock signature is not valid");
        keyImageUsed[uint(keccak256(abi.encode(_v,_r,_s)))] = true;
        
        renter_links[msg.sender] = _car;
        renter_hashlock[msg.sender] = bytes32(_message.content);
        renter_state[msg.sender]++;
        renter_start[msg.sender] = now;

        emit E_renterBooking(msg.sender, bytes32(_message.content), _secretLink);
    }

    function carBooking(
        address _renter,
        bytes32 _r,
        bytes32 _s,
        uint8   _v,
        RingMessage memory _message)
        public carAvailable() unusedKeyImage(_r, _s, _v)
    {
        require(car_balance[msg.sender] >= DEPOSIT, 'not enough deposit to start booking');
        require(isSignatureValid(_renter, _message, _v, _r, _s),'Hashlock signature is not valid');
        keyImageUsed[uint(keccak256(abi.encode(1,_v,_r,_s)))] = true;
        
        car_links[msg.sender] = _renter;
        car_hashlock[msg.sender] = bytes32(_message.content);
        car_state[msg.sender]++;
        car_start[msg.sender] = now;

        emit E_carBooking(msg.sender, bytes32(_message.content));
    }

    //Phase 3: Payment & reset state
    function carPayment(
        bytes32 _preimage,
        bytes32 _encryptedPreimage,
        bytes32 _newToken,
        bytes32 _r,
        bytes32 _s,
        uint8   _v,
        RingMessage memory _msg)
        public carBooked() unusedKeyImage(_r,_s,_v){
        require(car_hashlock[msg.sender] == keccak256(abi.encode(_preimage)), 'Not the appropriate value to open lock');
        require(isSignatureValid(car_links[msg.sender], _msg , _v, _r, _s),'Fee signature is not valid!');
        keyImageUsed[uint(keccak256(abi.encode(_v,_r,_s)))] = true;

        uint fee = (_msg.content - car_start[msg.sender])*car_price[msg.sender];
        car_state[msg.sender] = 1;
        car_balance[msg.sender] += fee;

        emit E_carPaid(msg.sender, _encryptedPreimage, _newToken);
    }

    function renterPayment(
        bytes32 _preimage,
        bytes32 _r,
        bytes32 _s,
        uint8   _v,
        RingMessage memory _msg)
        public renterBooked() unusedKeyImage(_r, _s, _v)
    {
        require(renter_hashlock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        require(isSignatureValid(renter_links[msg.sender], _msg, _v, _r, _s),'Fee signature is not valid!');
        keyImageUsed[uint(keccak256(abi.encode(_v,_r,_s)))] = true;

        renter_balance[msg.sender] -= _msg.content;
        renter_state[msg.sender] = 1;
    }

    //Dispute functions: Double booking and not ending booking
    //Double booking resolves privacy
    //1) Car already booked, renter was too late to initiate driving
    function undoBooking(
        bytes32 _r,
        bytes32 _s,
        uint8   _v,
        RingMessage memory _msg)
        public renterBooked() unusedKeyImage(_r, _s, _v){
        require(_msg.destination == renter_links[msg.sender],'Not the same car as booked');
        require(_msg.instance == 2, 'Not a hashlock');
        require(isSignatureValid(renter_links[msg.sender], _msg, _v, _r, _s),'Fee signature is not valid!');

        keyImageUsed[uint(keccak256(abi.encode(_v,_r,_s)))] = true;
        renter_state[msg.sender] = 1;
    }
    //2) If renter does not end after period is done --> car can force ending
    function forceEnd(address _renter, bytes32 _newToken) public carBooked() {
        require(car_start[msg.sender]+PERIOD < now, "Too early to force end booking");
        require(car_links[msg.sender] == _renter, "Not the appropriate renter");

        car_balance[msg.sender] += DEPOSIT;
        car_state[msg.sender] = 1;

        renter_balance[_renter] -= DEPOSIT;
        renter_state[_renter] = 1;

        emit E_forcedEnd(msg.sender, _newToken);
    }

    //Check whether correct address has signed off a certain hashed value
    function isSignatureValid(address _address, RingMessage memory _msg, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool) {
        bytes32 _hash = hashMessage(_msg);
        address _signer = ecrecover(_hash, _v, _r, _s);
        return(_signer == _address);
    }

    //Check whether correct address has signed off a certain hashed value
    function hashMessage(RingMessage memory _message) private pure returns(bytes32) {
        return keccak256(abi.encode(_message.destination, _message.instance, _message.content));
    }

    //Check balance of owner
    function getBalanceOwner(address _car) public view returns(uint) {
        return car_balance[_car];
    }
    //Check balance of renter
    function getBalanceRenter() public view returns(uint) {
        return renter_balance[msg.sender];
    }
    //Withdraw Balance, check this can't happen while driving!!
    function withdrawBalanceOwner(address _car)  public onlyCarOwner(_car){
        require(car_state[_car]==1, 'Car currently in use, wait until renter has returned car');
        car_state[_car] = 0;
        uint _value = car_balance[msg.sender];
        car_balance[_car] = 0;
        msg.sender.transfer(_value);
    }

    //Withdraw Balance, check  if this can't happen while driving!!
    function withdrawBalanceRenter() public{
        require(renter_state[msg.sender] == 1, 'Car currently in use, wait until renter has returned car');
        uint _value = renter_balance[msg.sender];
        msg.sender.transfer(_value);
    }

    //Fund balance owner
    function fundBalanceCar(address _car) public payable onlyCarOwner(_car) {
        car_balance[_car] += msg.value;
        if (car_balance[_car] > DEPOSIT){
            car_state[_car] = 1;
        }
    }

    //Fund balance renter --> should be adapted to zkay
    function fundBalanceRenter() public payable{
        require(renter_ppc[msg.sender] != bytes32(0), 'Validate yourself first!');
        renter_balance[msg.sender] += msg.value;
        if (renter_balance[msg.sender] > DEPOSIT){
            renter_state[msg.sender] = 1;
        }
    }
}


