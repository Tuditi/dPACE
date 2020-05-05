pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2; // Delete this in end version -> only needed to return structs
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
    mapping(address => uint)    car_price;
    mapping(address => uint)    car_endTime;
    mapping(address => uint)    car_balance;
    mapping(address => bool)    car_available;      //car is initialised
    mapping(address => mapping(bytes32 => bool)) car_receipts;       //holds consumed payments

    mapping(address => address) owner_car;          //private

    //Mappings to describe renter
    mapping(address => bytes32) renter_proof;       //ppim
    mapping(address => bytes)   renter_accessToken;
    mapping(address => uint)    renter_balance;
    mapping(address => address) renter_car;         //private
    mapping(address => bool)    renter_occupied;
    mapping(address => uint)    renter_startTime;
    mapping(address => mapping(bytes32 => bool)) renter_receipts; //holds paid receipts

    //Variables
    address REGISTRATION_SERVICE = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;//They are the ones who check whether the signature is valid
    address[] deployedCars;

    uint DEPOSIT = 5 ether;
    uint PENALTY_UNUSED = 1 ether; //Penalty if a certain time frame expires without the car being rent out
    uint TIME_PENALTY = 0.1 ether; //Penalty that motivates renter to use car as quickly as possible
    //Modifiers
    modifier callerIsOwner(address _car){
        require(_car == owner_car[msg.sender], 'This is not the car owner');
        _;
    }

    modifier carUndeployed(address _identifier){
        require(car_details[_identifier] == bytes32(0),'Car already initialized');
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
    event E_deployedCar(address indexed _carOwner, address indexed _carAddress, bytes32 _accessToken);
    event E_registeredRenter(address indexed _carRenter, uint _renterBalance, bytes32 _proof);
    event E_carRented(address indexed _carRenter, bytes _accessToken);
    event E_endRent(address indexed _identifier, uint _fee, bytes32 _newToken, bytes32 _newLocation);

    //1a. Create a car entry, when a new car is available for rent.
    function deployCar(
        address _car,
        bytes32 _accessToken,
        bytes32 _location,
        bytes32 _details,
        uint    _price
        )
        public
        checkDeposit()
        carUndeployed(_car)  //Otherwise already deployed car could be modified
        payable
    {
    car_location[_car] = _location;
    car_details[_car] = _details;
    car_available[_car] = true;
    car_price[_car] = _price;
    car_balance[_car] = msg.value;
    owner_car[msg.sender] = _car;


    deployedCars.push(_car);
    emit E_deployedCar(msg.sender, _car, _accessToken);
    }

    //1b. If a Renter has a signed proof that he is registered in the system and has put a deposit, he is entered inside the system.
    //Question: How should this proof look like to be a valid proof coupled to a specific user? Require proofIsValidFunction
    function enterRenter(
        bytes32 _proof,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public
        checkDeposit()
        renterUndeployed(msg.sender)
        payable
    {
        // Signature checking needs to be moved to rentCar, since validity can change over time/ Do we need to store v,r,s?
        require(isSignatureValid(REGISTRATION_SERVICE, _proof, _v, _r, _s), 'No valid proof of registration');

        renter_proof[msg.sender] = _proof;
        renter_balance[msg.sender] = msg.value;

        emit E_registeredRenter(msg.sender, msg.value, _proof);
    }

    //2 Book a car based on identifier and the access token of the car encrypted with the public key.
    // This accessToken gets decrypted by the car hardware and checked for validity
    function bookCar(address _car, bytes memory _encryptedAccessToken) public {
        require(renter_balance[msg.sender] >= DEPOSIT,'Not enough balance, please fund account');
        require(!renter_occupied[msg.sender], 'Please return previous car');

        renter_car[msg.sender] = _car;
        renter_occupied[msg.sender] = true;
        renter_accessToken[msg.sender] = _encryptedAccessToken;
        renter_startTime[msg.sender] = now;  //will be used to calculate fee

        emit E_carRented(msg.sender, _encryptedAccessToken);
    }

    //3 end the driving which is called by the car. 2 problems: it can call with any renter plus signature and receive a fee
    function endDrivingNormal(
        address _renter,
        bytes32 _newLocation,
        bytes32 _newToken,
        uint    _startTime,
        uint    _endTime,
        uint8   _v1, //Signatures need to be hidden
        uint8   _v2,
        bytes32 _r1,
        bytes32 _r2,
        bytes32 _s1,
        bytes32 _s2
        ) public {
        require(car_available[msg.sender], "Car is not initialised");
        require(isSignatureValid(
            _renter,
            keccak256(abi.encodePacked(_startTime)),
            _v1,
            _r1,
            _s1),
            'startTime doesnt have a valid signature'
            );
        require(isSignatureValid(
            _renter,
            keccak256(abi.encodePacked(_endTime)),
            _v2,
            _r2,
            _s2),
            'endTime doesnt have a valid signature'
            );


        uint _fee = (_endTime - _startTime) * car_price[msg.sender];

        car_accessToken[msg.sender] = _newToken;                //Owner deposit needs to be checked

        emit E_endRent(msg.sender, _fee, _newToken, _newLocation);
    }

    //4 User calls this function to end his rental period.
    //  His fee is calculated based on a value found in an emitted event.
    //  In order to mitigate replay attacks (e.g. to use a previous car fee) a receipt(~nonce)
    //  is added to a private mapping
    function endRentalNormal(
        uint    _fee,
        uint8   _v,
        bytes32 _r,
        bytes32 _s
        ) public {
        require(renter_occupied[msg.sender] == true, 'Not driving atm');
        bytes32 _receipt = keccak256(abi.encodePacked(_v,_r,_s));
        require(!renter_receipts[msg.sender][_receipt], 'Fee already paid');
        require(isSignatureValid(address(this), keccak256(abi.encodePacked(_fee)), _v, _r, _s), 'Fee wasnt signed off from car');

        renter_receipts[msg.sender][_receipt] = true;
        renter_balance[msg.sender] -= _fee;
        renter_occupied[msg.sender] = false;
        renter_car[msg.sender] = address(0);
    }

    
    //Check balance of owner
    function getBalanceOwner() public view returns(uint) {
        return car_balance[msg.sender];
    }

    //Check balance of renter
    function getBalanceRenter() public view returns(uint) {
        return renter_balance[msg.sender];
    }

    //Withdraw Balance, minimum of 5 ether has to be deposited as long as car is available to drive
    function withdrawBalanceCar(address _car) callerIsOwner(_car) public{
        uint _value = car_balance[_car] - 5 ether;
        require(_value > 0, 'Not enough balance');
        car_balance[msg.sender] = 5 ether;
        msg.sender.transfer(_value);
    }

    //Withdraw Balance, check  if this can't happen while driving!!
    function withdrawBalanceRenter() public{
        require(!renter_occupied[msg.sender], 'Car currently in use, wait until renter has returned car');
        uint _value = renter_balance[msg.sender];
        renter_balance[msg.sender] = 0;
        msg.sender.transfer(_value);
    }

    //Fund balance owner
    function fundBalanceOwner() public payable{
        require(owner_car[msg.sender] != address(0), 'Deploy car first');
        car_balance[owner_car[msg.sender]] += msg.value;
    }

    //Fund balance renter
    function fundBalanceRenter() public payable{
        require(renter_proof[msg.sender] != bytes32(0), 'Validate yourself first!');
        renter_balance[msg.sender] += msg.value;
    }


    //Structures used for testing
    struct car{
        address carHW;
        bytes32 accessToken;
        bytes32 details;
        bytes32 location;

        bool    available;
        uint    price;
        uint    endTime;
    }

    struct renter{
        address addr;
        address car;
        uint    balance;
        uint    startTime;
        bytes32 proof;
        bytes   accessToken;
        bool    occupied;
    }

    function getCar(address _car) public view returns(car memory){
        return car(
            _car,
            car_accessToken[_car],
            car_details[_car],
            car_location[_car],
            car_available[_car],
            car_price[_car],
            car_endTime[_car]
            );
    }

    function getOwner(address  _car) public view returns (address){
        return owner_car[_car];
    }

    function getRenter(address _renter) public view returns (renter memory){
        return renter(
            _renter,
            renter_car[_renter],
            renter_balance[_renter],
            renter_startTime[_renter],
            renter_proof[_renter],
            renter_accessToken[_renter],
            renter_occupied[_renter]
            );
    }
}
