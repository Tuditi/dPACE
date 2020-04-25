pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;
/* Author: David De Troch
The goal of this contract is to implement the basic architecture for an
aggregated car sharing application. This will be encrypted using zkay.
The state of the contract contains three entitities that can interact:
1. Car{
    Available bool,
    Owner address,
    CurrentDriver address,
    Details hash,
    Price,
    BalanceOwner,
    BalanceDriver,
    ContractStep uint, --> used for secure programming
}

2. Owner{
    Address
    Car
    balance
}

3. Renter{
    Address,
    Car,
    balance
}

These are all implemented in structs and
Car HW contact
{
  address: '0x5ba7c96BB7707A83AFC2150BfFC81715c3090F04',
  privateKey: '0x6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4',
  publicKey: '1fa124c4281fab15064cd5072f60bb6bd925aaa097b22d6fc6c61e019434349802f7898e3849f4ef6aaf8ce052cf6df8ca6ea6ff4072392f6726ae0e8db4760d'
}
*/

contract MassCarSharing{
    //Mappings to describe car
    mapping(address => bytes32) car_accessToken;    //private
    mapping(address => bytes32) car_location;
    mapping(address => bytes32) car_details;
    mapping(address => bool)    car_available;
    mapping(address => uint)    car_price;
    mapping(address => uint)    car_startTime;
    mapping(address!x => address@x) car_owner;          //private
    mapping(address!x => address@x) car_renter;         //private

    //Mappings to describe owner
    mapping(address => string)  owner_name;
    mapping(address!x => address@x) owner_car;          //private, because unlinkability needed between owner & car
    mapping(address!x => uint@x)    owner_balance;      //private

    //Mappings to describe renter
    mapping(address => string)  renter_name;
    mapping(address => bytes32) renter_proof;       //ppim
    mapping(address => bool)    renter_driving;     //private
    mapping(address!x => uint@x)    renter_balance;
    mapping(address!x => address@x) renter_car;         //private
    //Variables
    address REGISTRATION_SERVICE = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;//They are the ones who check whether the signature is valid
    uint DEPOSIT = 5 ether;

    //Modifiers
    modifier callerIsRenter(address _car){
        require(msg.sender == car_renter[_car], 'This is not the car renter');
        _;
    }

    modifier callerIsOwner(address _car){
        require(msg.sender == car_owner[_car], 'This is not the car owner');
        _;
    }

    modifier involvedParties(address _car){
        require((msg.sender == car_owner[_car]) || (msg.sender == car_renter[_car]) || (msg.sender == _car), 'Not part of the transaction');
        _;
    }

    modifier renterUndeployed(address _identifier){
        require(renter_proof[_identifier] == bytes32(0),'Renter already inside the system');
        _;
    }

    modifier checkDeposit(){
        require(msg.value >= DEPOSIT,'Not enough deposit to enter system');
        _;
    }

    //Events
    event E_deployedCar(address indexed _carOwner, address indexed _carAddress, uint _ownerBalance);
    event E_registeredRenter(address indexed _carRenter, uint _renterBalance, bytes32 _proof);
    event E_carRented(address indexed _carOwner, address indexed _carRenter, address _carAddress);
    event E_endRent(address indexed _endingParty, address indexed _identifier, uint _fee);

    //1a. Create a car entry, when a new car is available for rent.
    function deployCar(
        address _car,
        bytes32 _accessToken,
        bytes32 _location,
        bytes32 _details,
        uint    _price,
        string  memory _name
        )
        public
        checkDeposit()
        payable
    {
    require(car_details[_car] == bytes32(0),'car already initialized');
    car_accessToken[_car] = _accessToken;
    car_location[_car] = _location;
    car_details[_car] = _details;
    car_owner[_car] = reveal(msg.sender,_car);
    car_available[_car] = true;
    car_price[_car] = _price;

    owner_name[msg.sender] = _name;
    owner_car[msg.sender] = _car;
    owner_balance[msg.sender] = msg.value;

    emit E_deployedCar(msg.sender,owner_car[msg.sender], owner_balance[msg.sender]);
    }

    //1b. If a Renter has a signed proof that he is registered in the system and has put a deposit, he is entered inside the system.
    //Question: How should this proof look like to be a valid proof coupled to a specific user? Require proofIsValidFunction
    function enterRenter(
        string memory _name,
        bytes32 _proof,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public
        checkDeposit()
        renterUndeployed(msg.sender)
        payable
    {   // Signature checking needs to be moved to rentCar, since validity can change over time/ Do we need to store v,r,s?
        require(isSignatureValid(REGISTRATION_SERVICE, _proof, _v, _r, _s), 'No valid proof of registration');

        renter_name[msg.sender] = _name;
        renter_proof[msg.sender] = _proof;
        renter_balance[msg.sender] = msg.value;

        emit E_registeredRenter(msg.sender, msg.value, _proof);
    }

    //2 Book a car based on identifier
    function rentCar(address@me _car) public {
        require(reveal(renter_balance[msg.sender] >= DEPOSIT,all),'Not enough balance, please fund account!');
        require(reveal(owner_balance[car_owner[_car]] >= DEPOSIT,all),'Owner does not have enough balance, please fund account!'); //renter can't access this value
        require(!renter_driving[msg.sender], 'Please return previous ca!');
        require(car_available[_car], 'Car currently in use, pick other car!');

        car_renter[_car] = reveal(msg.sender,_car);
        car_available[_car] = false;
        car_startTime[_car] = now;
        renter_car[msg.sender] = _car;
        renter_driving[msg.sender] = true;
        //emit E_carRented(car_owner[_car], car_renter[_car], _car);
    }

    //3 End booking, needs to be public, because it can be called by owner/renter
    function endRentCar(address@me _car) public involvedParties(_car) {
        require(car_available[_car] == false, "Car is not rented out");
        uint _fee = (now - car_startTime[_car]) * car_price[_car];
        owner_balance[car_owner[_car]] += reveal(_fee, ;    //Not going to work if called by renter --> doesn't have access to private value, let car call this?
        renter_balance[car_renter[_car]] -= reveal(_fee, me);
        renter_driving[car_renter[_car]] = false;
        car_renter[_car] = address(0);
        car_available[_car] = true;                   //Owner deposit needs to be checked
        //emit E_endRent(msg.sender, _car, _fee);

    }

    //Check whether registry service has signed off that a renter is allowed to drive the car
    function isSignatureValid(address _address, bytes32 _proof, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool) {
        address _signer = ecrecover(_proof, _v, _r, _s);  //possible some manipulation needed to get proof in proper form...
        return(_signer == _address);
    }

    //Check balance of owner
    function getBalanceOwner() public view returns(uint) {
        return owner_balance[msg.sender];
    }

    //Check balance of renter
    function getBalanceRenter() public view returns(uint) {
        return renter_balance[msg.sender];
    }

    //Withdraw Balance, check if this can't happen while driving!!
    function withdrawBalanceOwner() public{
        require(car_available[owner_car[msg.sender]], 'Car currently in use, wait until renter has returned car');
        car_available[owner_car[msg.sender]] = false;
        uint _value = owner_balance[msg.sender];
        owner_balance[msg.sender] = 0;
        msg.sender.transfer(_value);
    }

    //Withdraw Balance, check  if this can't happen while driving!!
    function withdrawBalanceRenter() public{
        require(!renter_driving[msg.sender], 'Car currently in use, wait until renter has returned car');
        uint _value = renter_balance[msg.sender];
        renter_balance[msg.sender] = 0;
        msg.sender.transfer(_value);
    }

    //Fund balance owner
    function fundBalanceOwner() public payable{
        require(owner_car[msg.sender] != address(0), 'Deploy car first');
        owner_balance[msg.sender] += msg.value;
    }

    //Fund balance renter
    function fundBalanceRenter() public payable{
        require(renter_proof[msg.sender] != bytes32(0), 'Validate yourself first!');
        renter_balance[msg.sender] += msg.value;
    }


    //Structures used for testing
    struct car{
        address carHW;
        address owner;
        address renter;

        bytes32 accessToken;
        bytes32 details;
        bytes32 location;

        bool    available;
        uint    price;
        uint    startTime;
    }

    struct owner{
        address addr;
        address car;
        string  name;
        uint    balance;
    }

    struct renter{
        address addr;
        address car;
        uint    balance;
        bytes32 proof;
        string  name;    //How to encode this?
        bool    driving;
    }

    function getCar(address _car) public view returns(car memory){
        return car(
            _car,
            car_owner[_car],
            car_renter[_car],
            car_accessToken[_car],
            car_details[_car],
            car_location[_car],
            car_available[_car],
            car_price[_car],
            car_startTime[_car]
            );
    }

    function getOwner(address  _owner) public view returns (owner memory){
        return owner(
            _owner,
            owner_car[_owner],
            owner_name[_owner],
            owner_balance[_owner]
        );
    }

    function getRenter(address _renter) public view returns (renter memory){
        return renter(
            _renter,
            renter_car[_renter],
            renter_balance[_renter],
            renter_proof[_renter],
            renter_name[_renter],
            renter_driving[_renter]
            );
    }
}
