pragma solidity ^0.6.4;
/* Author: David De Troch
The goal of this contract is to implement the a tumbler that can be used for aggregated car sharing
providing an application specifici payment hub. This payment hub is able to provide anonimity between
car renter and driver.
Contract consists of thre phases:

Phase 1: Deploy car, renter and tumbler
Phase 2: Booking and Payment of car
Phase 3: Withdraw Balance
*/
import './Signature.sol';

contract carSharing is Signature{

    //Renter Mappings
    mapping(address => uint)        renter_balance;
    mapping(address => uint)        renter_state;
    mapping(address => uint)        renter_start;
    mapping(address => address[])   renter_links;
    mapping(address => bytes32)     renter_hashlock;
    mapping(address => bytes32)     renter_ppc;


    //Car Mappings
    mapping(address => uint)        car_balance;
    mapping(address => uint)        car_state;
    mapping(address => uint)        car_price;
    mapping(address => uint)        car_start;
    mapping(address => address)     car_owner;
    mapping(address => address[])   car_links;
    mapping(address => bytes32)     car_hashlock;
    mapping(address => bytes32)     car_token;

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
        require(renter_state[msg.sender] == 1,'Renter is not booked');
        _;
    }
    modifier onlyCarOwner(address _car){
        require(car_owner[_car]==msg.sender, 'Only owner can view balance');
        _;
    }
    //Phase 1: renter and car are deployed as entities on the blockchain
    function deployRenter(bytes32 _ppc, uint8 _v, bytes32 _r, bytes32 _s) public payable checkDeposit() {
        require(isSignatureValid(REGISTRATION_SERVICE, _ppc, _v, _r, _s), "No valid PPC_renter");
        renter_state[msg.sender] = 1;
        renter_balance[msg.sender] = msg.value;
        renter_ppc[msg.sender] = _ppc;
        emit E_deployRenter(msg.sender, _ppc);
    }

    function deployCar(address _address, bytes32 _details, uint _price) public payable checkDeposit() {
        car_balance[_address] = msg.value;
        car_owner[_address] = msg.sender;
        car_price[_address] = _price;
        emit E_deployCar(_address, _details);
    }
    
    function validateCar(bytes32 _token, bytes32 _location) public {
        require(car_owner[msg.sender] != address(0),'Car not yet deployed');
        require(car_state[msg.sender] == 0, 'Car not yet validated');
        car_state[msg.sender] = 1;
        emit E_carAvailable(msg.sender, _token, _location, car_price[msg.sender]);
    }

    //Phase 2: A booking is initiated
    function renterBooking(bytes32 _hashlock, bytes32 _secretLink, uint256[] memory _rSignature) public renterAvailable() {
        require(renter_balance[msg.sender] >= DEPOSIT, 'not enough deposit to start booking');
        require(!keyImageUsed[_rSignature[0]],"Key image already used!");
        require(RingVerify(_hashlock, _rSignature),"Ring signature is not valid");

        keyImageUsed[_rSignature[0]] = true;
        renter_hashlock[msg.sender] = _hashlock;
        renter_state[msg.sender]++;
        renter_start[msg.sender] = now;

        emit E_renterBooking(msg.sender, _hashlock, _secretLink);
    }

    function carBooking(bytes32 _hashlock, uint256[] memory _rSignature) public carAvailable() {
        require(car_balance[msg.sender] >= DEPOSIT, 'not enough deposit to start booking');
        require(!keyImageUsed[_rSignature[0]],"Key image already used");
        require(RingVerify(_hashlock, _rSignature),"Ring signature is not valid");

        keyImageUsed[_rSignature[0]] = true;
        
        car_hashlock[msg.sender] = _hashlock;
        car_state[msg.sender]++;
        car_start[msg.sender] = now;

        emit E_carBooking(msg.sender, _hashlock);
    }

    //Phase 3: Payment & reset state
    function renterPayment(
        bytes32 _preimage,
        uint    _fee,
        uint256[] memory _rSignature
        ) public renterBooked() {
        require(renter_hashlock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        require(!keyImageUsed[_rSignature[0]],"Key image already used!");
        require(RingVerify(keccak256(abi.encode(_fee)), _rSignature),"Ring signature is not valid!");
        
        renter_balance[msg.sender] -= _fee;
        renter_state[msg.sender] = 1;
    }

    function carPayment(
        bytes32          _preimage,
        bytes32          _encryptedPreimage,
        bytes32          _newToken,
        uint             _timestamp,
        uint256[] memory _rSignature
        ) public carBooked() {
        require(car_hashlock[msg.sender] == keccak256(abi.encode(_preimage)), 'Not the appropriate value to open lock');
        require(!keyImageUsed[_rSignature[0]],"Key image already used!");
        require(RingVerify(keccak256(abi.encode(_timestamp)), _rSignature),"Ring signature is not valid!");

        keyImageUsed[_rSignature[0]] = true;
        uint fee = (_timestamp - car_start[msg.sender])*car_price[msg.sender];
        car_state[msg.sender] = 1;
        car_balance[msg.sender] += fee;
        emit E_carPaid(msg.sender, _encryptedPreimage, _newToken);
    }

    //Dispute resolution dissolves privacy
    //TO DO

    //Check whether correct address has signed off a certain hashed value
    function isSignatureValid(address _address, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool) {
        address _signer = ecrecover(_hash, _v, _r, _s);
        return(_signer == _address);
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


