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

contract carTumbler{

    address tumbler;
    uint    tumblerBalance;

    //Renter
    mapping(address => uint)    renter_balance;
    mapping(address => bytes32) renter_hashLock;
    mapping(address => uint)    renter_state;
    mapping(address => uint)    renter_start;
    mapping(address => bytes32) renter_fee;
    mapping(address => mapping(uint => bool))    renter_invoices;


    //Car
    mapping(address => uint)    car_balance;
    mapping(address => uint)    car_price;
    mapping(address => bytes32) car_hashLock;
    mapping(address => bool)    car_available;
    mapping(address => uint)    car_state;
    mapping(address => uint)    car_start;
    mapping(address => bytes32) car_fee;
    mapping(address => mapping(uint => bool))    car_invoices;

    //Groupings of published fees
    bytes32[] carFees;
    bytes32[] renterFees;

    //Constants
    uint DEPOSIT    = 5 ether;
    uint PERIOD     = 300;

    //Events
    event E_deployRenter(address indexed _address);
    event E_deployCar(address indexed _address, bytes32 indexed _token);
    event E_carBooking(address indexed, bytes32 _hashLock);
    event E_renterBooking(address indexed, bytes32 _hashLock, bytes32 _secretLink);
    event E_carEnd(address indexed, bytes32 _newLock, uint _fee);
    event E_renterEnd(address indexed, bytes32 _newLock, bytes32 _Fee);
    event E_carPaid(address indexed);
    event E_renterPaid(address indexed);

    //Modifiers
    modifier checkDeposit(){
        require(msg.value >= DEPOSIT,'Not enough deposit to enter system');
        _;
    }

    modifier carAvailable(){
        require(car_state[msg.sender] == 0, 'car is unavailabl');
        _;
    }

    modifier renterAvailable(){
        require(renter_state[msg.sender] == 0, 'renter is unavailable');
        _;
    }

    modifier carBooked(){
        require(car_state[msg.sender] == 1);
        _;
    }
    modifier renterBooked(){
        require(renter_state[msg.sender] == 1);
        _;
    }

    modifier carEnded(){
        require(car_state[msg.sender] == 2);
        _;
    }

    modifier renterEnded(){
        require(renter_state[msg.sender] == 2);
        _;
    }

    constructor() public payable{
        require(msg.value >= 50 ether, 'Not enough collateral');
        tumbler = msg.sender;
        tumblerBalance = msg.value;
    }

    //Phase 0: renter and car are deployed as entities on the blockchain
    function deployRenter() public payable checkDeposit() {
        renter_balance[msg.sender] = msg.value;
        emit E_deployRenter(msg.sender);
    }

    function deployCar(address _address, bytes32 _token) public payable checkDeposit() {
        car_balance[msg.sender] = msg.value;
        emit E_deployCar(_address, _token);
    }

    //Phase 1: A booking is initiated
    function renterBooking(bytes32 _hashLock, bytes32 _secretLink) public renterAvailable() {
        require(renter_balance[msg.sender] >= DEPOSIT, 'not enough deposit to start booking');
        renter_hashLock[msg.sender] = _hashLock;
        renter_state[msg.sender]++;
        renter_start[msg.sender] = now;
        emit E_renterBooking(msg.sender, _hashLock, _secretLink);
    }

    function carBooking(bytes32 _hashLock) public carAvailable() {
        require(car_balance[msg.sender] >= DEPOSIT, 'not enough deposit to start booking');
        car_hashLock[msg.sender] = _hashLock;
        car_state[msg.sender]++;
        car_start[msg.sender] = now;
        emit E_carBooking(msg.sender, _hashLock);
    }

    //Phase 2: After driving is finished they change their state on-chain, car publishes fee on-chain
    function renterEnd(bytes32 _preimage, bytes32 _newLock, uint _fee) public renterBooked() {
        require(renter_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        require(_fee > 0, 'invalid fee, check through range proof');
        renter_hashLock[msg.sender] = _newLock;
        renter_fee[msg.sender] = _fee;
        renterFees.push(_fee);               //Issue here that it is appended at the end
        emit E_renterEnd(msg.sender, _newLock, _blindedFee);
    }

    function carEnd(bytes32 _preimage, bytes32 _newLock) public carBooked() {
        require(car_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        car_hashLock[msg.sender] = _newLock;
        uint _fee = (now - car_start[msg.sender])*car_price[msg.sender];    //Fee calculation happens at car side
        carFees.push(keccak256(abi.encodePacked(_fee)));                  //Issue here that it is appended at the end
        emit E_carEnd(msg.sender, _newLock, _fee);
    }

    //Phase 3: Payment & reset state
    function renterPayment(bytes32 _preimage, uint _fee, uint _random) public renterEnded() {
        require(renter_fee[msg.sender] == keccak256(abi.encodePacked(_fee, _random)), 'not the valid blinder');
        require(renter_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        renter_state[msg.sender] = 0;
        renter_balance[msg.sender] -= _fee;
    }

    function carPayment(bytes32 _preimage, uint _fee, uint _random, bytes32 _newToken) public carEnded() {
        require(car_fee[msg.sender] == keccak256(abi.encodePacked(_fee, _random)), 'not the valid blinder');
        require(car_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        car_state[msg.sender] = 0;
        car_balance[msg.sender] += _fee;
        emit E_carPaid(msg.sender); 
    }

    //Dispute resolution dissolves privacy



    //Check whether correct address has signed off a certain hashed value
    function isSignatureValid(address _address, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool) {
        address _signer = ecrecover(_hash, _v, _r, _s);
        return(_signer == _address);
    }

    
}
