pragma solidity ^0.5;
pragma experimental ABIEncoderV2;
/* Author: David De Troch
The goal of this contract is to implement a platform that can be used for aggregated car sharing
providing an application specific payment hub. This payment hub is able to provide anonimity between
car renter and driver if ring signatures and zero-knowledge proofs are implemented.
Ring signatures are required on the Message:
https://cryptonote.org/whitepaper.pdf
Zero-knowledge proofs should hide the renter's balance:
https://files.sri.inf.ethz.ch/website/papers/ccs19-zkay.pdf

The contract consists of three phases:
Phase 1: Deploy car, renter and tumbler
Phase 2: Booking and Payment of car
Phase 3: Withdraw Balance
*/
//Import different libraries necessary to perform zk-proofs
import './PKI.sol';
import './Verify_deployRenter.sol';
import './Verify_renterBooking.sol';
import './Verify_renterPayment.sol';
import './Signature.sol';

contract dPACE {
    //Renter Mappings
    mapping(address => uint) public renter_balance; //Contains the balance in encrypted format
    mapping(address => uint) public renter_state; //Contains the renter's state => (0 = uninitialized, 1 = initialized, 2 = booked)
    mapping(address => address) public renter_links; //Contains the possible links during a rental period => mitigates set intersection
    mapping(address => bytes32) public renter_hashlock; //Ensures state of the renter only changes if preimage is released
    mapping(address => bytes32) public renter_ppc; //Privacy-Preserving Credential

    //Car Mappings
    mapping(address => uint) public car_balance;
    mapping(address => uint) public car_state; //0 = uninitialized, 1 = initialized, 2 = booked,
    mapping(address => uint) public car_price;
    mapping(address => uint) public car_start;
    mapping(address => address) public car_owner;
    mapping(address => address) public car_links;
    mapping(address => bytes32) public car_hashlock;

    //Message where instance (1 = hashlock, 2 =fee, 3 = timestamp) specifies the content.
    //The content will be signed by a ring signature.
    struct Message {
        address destination;
        bool hashlock;
        uint content;
    }

    //Groupings of published signatures
    mapping(uint256 => bool) keyImageUsed;
    mapping(uint256 => bool) PPCUsed;

    //Constants used inside the contract.
    uint public DEPOSIT = 0.5 ether;
    uint public PERIOD = 86400;
    address public REGISTRATION_SERVICE = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;

    //Events used for communicating to the outside world
    event E_deployRenter(address indexed addr, bytes32 indexed ppc);
    event E_deployCar(address indexed addr, bytes32 details);
    event E_carAvailable(address indexed addr, bytes32 indexed token, string location, uint price);
    event E_carBooking(address indexed addr, bytes32 hashlock);
    event E_renterBooking(
        address indexed addr,
        bytes32 indexed hashlock,
        bytes32 indexed secretLink
    );
    event E_carPaid(
        address indexed addr,
        bytes32 indexed encryptedPreimage,
        uint indexed fee,
        bytes32 newToken,
        string location
    );
    event E_renterPaid(address indexed addr);
    event E_forcedEnd(address indexed addr, bytes32 indexed newToken, string location);

    //External Contracts used in dPACE (type = contract name, value = variable);
    PKI genPublicKeyInfrastructure;
    Verify_deployRenter Verify_deployRenter_var;
    Verify_renterBooking Verify_renterBooking_var;
    Verify_renterPayment Verify_renterPayment_var;
    Signature ringSignature;

    //Constructor specifies addresses of contracts on which dPACE depends
    constructor(
        PKI _PKI,
        Verify_deployRenter _verify_deployRenter,
        Verify_renterBooking _verify_renterBooking,
        Verify_renterPayment _verify_renterPayment,
        Signature _signature
    ) public {
        genPublicKeyInfrastructure = _PKI;
        Verify_deployRenter_var = _verify_deployRenter;
        Verify_renterBooking_var = _verify_renterBooking;
        Verify_renterPayment_var = _verify_renterPayment;
        ringSignature = _signature;
    }

    //Modifiers
    modifier checkDeposit() {
        require(msg.value >= DEPOSIT, 'Not enough deposit to enter system');
        _;
    }
    modifier carAvailable() {
        require(car_state[msg.sender] == 1, 'Car is unavailable');
        _;
    }
    modifier renterAvailable() {
        require(renter_state[msg.sender] == 1, 'Renter is unavailable');
        _;
    }
    modifier carBooked() {
        require(car_state[msg.sender] == 2, 'Car is not booked');
        _;
    }
    modifier renterBooked() {
        require(renter_state[msg.sender] == 2, 'Renter is not booked');
        _;
    }
    modifier onlyCarOwner(address _car) {
        require(car_owner[_car] == msg.sender, 'Only owner can view balance');
        _;
    }

    modifier unusedKeyImage(uint256 _keyImage) {
        require(!keyImageUsed[_keyImage], 'Key image already used!');
        _;
    }

    modifier unusedPPC(
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) {
        require(!PPCUsed[uint(keccak256(abi.encode(_v, _r, _s)))], 'Key image already used!');
        _;
    }

    //Phase 1: renter and car are deployed as entities on the blockchain
    function deployRenter(
        bytes32 _ppc,
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        uint[8] memory Verify_deployRenterproof,
        uint[1] memory genParam
    ) public payable unusedPPC(_r, _s, _v) {
        require(msg.value >= DEPOSIT, 'not enough deposit');
        require(REGISTRATION_SERVICE == ecrecover(_ppc, _v, _r, _s), 'No valid PPC_renter');

        //Check zk-proof--> automatically generated by zkay:

        uint[1] memory genHelper;
        require(msg.value >= DEPOSIT);
        genHelper[0] = msg.value;
        uint256[] memory geninputs = new uint256[](3);
        geninputs[0] = genHelper[0];
        geninputs[1] = genParam[0];
        geninputs[2] = genPublicKeyInfrastructure.getPk(msg.sender);
        uint128[2] memory genHash = get_hash(geninputs);
        Verify_deployRenter_var.check_verify(
            Verify_deployRenterproof,
            [genHash[0], genHash[1], uint(1)]
        );

        //If valid proof encrypted balance == msg.value:

        PPCUsed[uint(keccak256(abi.encode(_v, _r, _s)))] = true;
        renter_state[msg.sender] = 1;
        renter_balance[msg.sender] = genParam[0];
        renter_ppc[msg.sender] = _ppc;

        emit E_deployRenter(msg.sender, _ppc);
    }

    //Car owner deploys the car together with a deposit
    function deployCar(
        address _address,
        bytes32 _details,
        uint _price
    ) public payable checkDeposit {
        car_balance[_address] = msg.value;
        car_owner[_address] = msg.sender;
        car_price[_address] = _price;
        emit E_deployCar(_address, _details);
    }

    //Car validates itself by sending a transaction to the smart contract containing a token and its location
    function validateCar(bytes32 _token, string memory _location) public {
        require(car_owner[msg.sender] != address(0), 'Car not yet deployed');
        require(car_state[msg.sender] == 0, 'Car not yet validated');
        car_state[msg.sender] = 1;
        emit E_carAvailable(msg.sender, _token, _location, car_price[msg.sender]);
    }

    //Phase 2: A booking is initiated
    function renterBooking(
        address _car,
        bytes32 _secretLink,
        uint256[] memory _signature,
        Message memory _message,
        uint[8] memory Verify_renterBookingproof,
        uint[1] memory genParam
    ) public renterAvailable unusedKeyImage(_signature[0]) {
        require(_message.destination == msg.sender, 'Signature not for this receiver');
        require(
            ringSignature.RingVerify(_message.content, _signature),
            'Ring Signature is invalid'
        );

        //Verify whether renter has enough balance:
        require(genParam[0] == 1, 'not enough deposit to start booking');
        uint[2] memory genHelper;
        genHelper[0] = renter_balance[msg.sender];
        genHelper[1] = DEPOSIT;
        uint256[] memory geninputs = new uint256[](3);
        geninputs[0] = genHelper[0];
        geninputs[1] = genHelper[1];
        geninputs[2] = genParam[0];
        uint128[2] memory genHash = get_hash(geninputs);
        Verify_renterBooking_var.check_verify(
            Verify_renterBookingproof,
            [genHash[0], genHash[1], uint(1)]
        );

        //Key Image has to be stored as used:
        keyImageUsed[_signature[0]] = true;

        //Change state renter
        renter_links[msg.sender] = _car;
        renter_hashlock[msg.sender] = bytes32(_message.content);
        renter_state[msg.sender]++;

        emit E_renterBooking(msg.sender, bytes32(_message.content), _secretLink);
    }

    function carBooking(
        address _renter,
        uint256[] memory _signature,
        Message memory _message
    ) public carAvailable unusedKeyImage(_signature[0]) {
        require(car_balance[msg.sender] >= DEPOSIT, 'not enough deposit to start booking');
        require(
            ringSignature.RingVerify(_message.content, _signature),
            'Ring Signature is invalid'
        );

        //Key Image has to be stored as used:
        keyImageUsed[_signature[0]] = true;

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
        string memory _location,
        uint256[] memory _signature,
        Message memory _msg
    ) public carBooked unusedKeyImage(_signature[0]) {
        require(
            car_hashlock[msg.sender] == keccak256(abi.encodePacked(_preimage)),
            'Not the right preimage'
        );
        require(ringSignature.RingVerify(_msg.content, _signature), 'Ring Signature is invalid');

        keyImageUsed[_signature[0]] = true;

        uint fee = (_msg.content - car_start[msg.sender]) * car_price[msg.sender];
        car_state[msg.sender] = 1;
        car_balance[msg.sender] += fee;

        emit E_carPaid(msg.sender, _encryptedPreimage, fee, _newToken, _location);
    }

    function renterPayment(
        bytes32 _preimage,
        uint256[] memory _signature,
        Message memory _msg,
        uint[8] memory Verify_renterPaymentproof,
        uint[1] memory genParam
    ) public renterBooked unusedKeyImage(_signature[0]) {
        require(
            renter_hashlock[msg.sender] == keccak256(abi.encodePacked(_preimage)),
            'Not the appropriate value to open lock'
        );
        require(ringSignature.RingVerify(_msg.content, _signature), 'Ring Signature is invalid');
        keyImageUsed[_signature[0]] = true;
        // Zero-knowledge proof that encrypted new balance = prev balance - encrypted fee

        uint[3] memory genHelper;
        genHelper[0] = _msg.content;
        genHelper[1] = renter_balance[msg.sender];
        genHelper[2] = _msg.content;
        renter_balance[msg.sender] = genParam[0];
        uint256[] memory geninputs = new uint256[](6);
        geninputs[0] = genHelper[0];
        geninputs[1] = genPublicKeyInfrastructure.getPk(msg.sender);
        geninputs[2] = genHelper[1];
        geninputs[3] = genHelper[2];
        geninputs[4] = genParam[0];
        geninputs[5] = genPublicKeyInfrastructure.getPk(msg.sender);
        uint128[2] memory genHash = get_hash(geninputs);
        Verify_renterPayment_var.check_verify(
            Verify_renterPaymentproof,
            [genHash[0], genHash[1], uint(1)]
        );

        //Update state if zk-proof checks
        renter_balance[msg.sender] = genParam[0];
        renter_state[msg.sender] = 1;
    }

    //Dispute functions: Double booking and not ending booking
    //Double booking resolves privacy
    //1) Car already booked, renter was too late to initiate driving
    function cancelBooking(
        uint256[] memory _signature,
        Message memory _msg
    ) public renterBooked unusedKeyImage(_signature[0]) {
        require(_msg.destination == renter_links[msg.sender], 'Not the same car as booked');
        require(_msg.hashlock, 'Not a hashlock');

        keyImageUsed[_signature[0]] = true;
        renter_state[msg.sender] = 1;
    }

    //2) If renter does not end after period is done --> car can force ending
    function forceEnd(
        address _renter,
        bytes32 _newToken,
        string memory _location
    ) public carBooked {
        require(car_start[msg.sender] + PERIOD < now, 'Too early to force end booking');
        require(renter_links[_renter] == msg.sender, 'Not the appropriate renter');

        car_balance[msg.sender] += DEPOSIT;
        car_state[msg.sender] = 1;

        renter_balance[_renter] -= DEPOSIT;
        renter_state[_renter] = 1;

        emit E_forcedEnd(msg.sender, _newToken, _location);
    }

    //Check whether correct address has signed off a certain hashed value
    function isSignatureValid(
        address _address,
        Message memory _msg,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (bool) {
        bytes32 _hash = hashMessage(_msg);
        address _signer = ecrecover(_hash, _v, _r, _s);
        return (_signer == _address);
    }

    //Check whether correct address has signed off a certain hashed value
    function hashMessage(Message memory _message) private pure returns (bytes32) {
        return keccak256(abi.encode(_message.destination, _message.hashlock, _message.content));
    }

    //Hashing function generated by zkay
    function get_hash(uint[] memory preimage) public pure returns (uint128[2] memory) {
        // start with just the first element
        bytes32 hash = bytes32(preimage[0]);

        // add one value after the other to the hash
        for (uint i = 1; i < preimage.length; i++) {
            bytes memory packed = abi.encode(hash, preimage[i]);
            hash = sha256(packed);
        }

        // split result into 2 parts (needed for zokrates)
        uint hash_int = uint(hash);
        uint128 part0 = uint128(hash_int / 0x100000000000000000000000000000000);
        uint128 part1 = uint128(hash_int);
        return [part0, part1];
    }

    //Check balance of owner
    function getBalanceOwner(address _car) public view returns (uint) {
        return car_balance[_car];
    }

    //Check balance of renter
    function getBalanceRenter() public view returns (uint) {
        return renter_balance[msg.sender];
    }

    //Withdraw Balance, check this can't happen while driving!
    function withdrawBalanceOwner(address _car) public onlyCarOwner(_car) {
        require(car_state[_car] == 1, 'Car currently in use, wait until renter has returned car');
        car_state[_car] = 0;
        uint _value = car_balance[msg.sender];
        car_balance[_car] = 0;
        msg.sender.transfer(_value);
    }

    //Withdraw Balance, check if this can't happen while driving!
    function withdrawBalanceRenter() public {
        require(
            renter_state[msg.sender] == 1,
            'Car currently in use, wait until renter has returned car'
        );
        uint _value = renter_balance[msg.sender];
        msg.sender.transfer(_value);
    }

    //Fund balance owner
    function fundBalanceCar(address _car) public payable onlyCarOwner(_car) {
        car_balance[_car] += msg.value;
        if (car_balance[_car] > DEPOSIT) {
            car_state[_car] = 1;
        }
    }

    //Fund balance renter --> should be adapted to zkay
    function fundBalanceRenter() public payable {
        require(renter_ppc[msg.sender] != bytes32(0), 'Validate yourself first!');
        renter_balance[msg.sender] += msg.value;
        if (renter_balance[msg.sender] > DEPOSIT) {
            renter_state[msg.sender] = 1;
        }
    }
}
