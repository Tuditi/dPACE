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
    mapping(address => uint)    renter_balance;
    mapping(address => uint)    renter_state;
    mapping(address => uint)    renter_start;
    mapping(address => bytes32) renter_hashLock;
    mapping(address => bytes32) renter_fee;
    mapping(address => bytes32) renter_ppc;
    mapping(address => bool)    renter_validated;


    //Car Mappings
    mapping(address => address) car_owner;
    mapping(address => uint)    car_balance;
    mapping(address => uint)    car_price;
    mapping(address => bytes32) car_hashLock;
    mapping(address => bytes32) car_token;
    mapping(address => uint)    car_state;
    mapping(address => uint)    car_start;
    mapping(address => bytes32) car_fee;
    mapping(address => mapping(uint => bool))    car_invoices;

    //Groupings of published fees
    bytes32[] carFees;
    bytes32[] renterFees;

    //Constants
    uint DEPOSIT    = 5 ether;
    uint PERIOD     = 86400;
    address REGISTRATION_SERVICE = address(0);

    //Events
    event E_deployRenter(address indexed _address, bytes32 _ppc);
    event E_deployCar(address indexed _address, bytes32 _details);
    event E_carAvailable(address indexed _address, bytes32 indexed _token, bytes32 _location, uint _price);
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
        require(car_state[msg.sender] == 0, 'car is unavailable');
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

    //Phase 1: renter and car are deployed as entities on the blockchain
    function deployRenter(bytes32 _ppc, uint8 _v, bytes32 _r, bytes32 _s) public payable checkDeposit() {
        require(isSignatureValid(REGISTRATION_SERVICE, _ppc, _v, _r, _s), "No valid PPC_renter");
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

    //Phase 3: Payment & reset state
    function renterPayment(bytes32 _preimage, uint _fee, uint _random) public renterBooked() {
        require(renter_fee[msg.sender] == keccak256(abi.encodePacked(_fee, _random)), 'not the valid blinder');
        require(renter_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        renter_state[msg.sender] = 0;
        renter_balance[msg.sender] -= _fee;
    }

    function carPayment(bytes32 _preimage, uint _fee, uint _random, bytes32 _newToken) public carBooked() {
        require(car_fee[msg.sender] == keccak256(abi.encodePacked(_fee, _random)), 'not the valid blinder');
        require(car_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        car_state[msg.sender] = 0;
        car_balance[msg.sender] += _fee;
        emit E_carPaid(msg.sender); 
    }

    /*function generateSignature(string memory message, uint256 nonce, uint256[] memory data) public returns(uint256[32] memory signature) {
        return RingSign(message, nonce, data);
    }

    function isRingSignatureValid(string memory message, uint256 nonce, uint256[] memory signature) public returns(bool){
        return RingVerify(message, nonce, signature);
    }*/

    //Dispute resolution dissolves privacy
    //TO DO

    //Check whether correct address has signed off a certain hashed value
    function isSignatureValid(address _address, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool) {
        address _signer = ecrecover(_hash, _v, _r, _s);
        return(_signer == _address);
    }
}


