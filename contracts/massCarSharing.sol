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
*/

contract MassCarSharing{
    //Structures stored inside MassCarSharing
    struct car{
        address owner;
        address renter;
        address carHW;

        uint8   contractStep;
        uint    pricePerBlock;
        uint    driveStartTime;

        bytes   accessToken;        //How to encode this?
        string  location;
        string  identifier;
    }

    struct owner{
        address addr;
        uint    balance;

        string  name;
        string  carIdentifier;
    }

    struct renter{
        address addr;
        uint    balance;

        bytes32 proof;
        bool    validated;
        string  carIdentifier;
    }

    //Variables
    address LocationContract;
    address REGISTRATION_SERVICE = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;//They are the ones who check whether the signature is valid
    uint DEPOSIT = 5 ether;

    mapping (string  => car)    carList;
    mapping (address => owner)  ownerList;
    mapping (address => renter) renterList;

    //Modifiers
    modifier callerIsRenter(car storage _car){
        require(msg.sender == _car.renter, 'This is not the car renter');
        _;
    }

    modifier callerIsOwner(car storage _car){
        require(msg.sender == _car.owner, 'This is not the car owner');
        _;
    }
    
    modifier involvedParties(car storage _car){
        require((msg.sender == _car.owner) || (msg.sender == _car.renter) || (msg.sender == _car.carHW), 'Not part of the transaction');
        _;
    }

    modifier carUndeployed(string memory _identifier){
        require(carList[_identifier].owner == address(0),'Car already initialized');
        _;
    }

    //Events
    event E_deployedCar(address indexed _carOwner, string _identifier, uint _ownerBalance);
    event E_registeredRenter(address indexed _carRenter, uint _renterBalance, bytes32 _proof);
    event E_carRented(address indexed _carOwner, address indexed _carRenter, string _identifier, bytes _accessToken);
    event E_endRent(address indexed _endingParty, string _identifier, uint _fee);

    //1a. Create a car entry, when a new car is available for rent.
    function deployCar(
        string memory _location,
        string memory _identifier,
        string memory _ownerName,
        bytes  memory _accessToken,
        uint          _pricePerHour
        )
        public
        carUndeployed(_identifier)                                               //Otherwise already deployed car could be modified
        payable
    {
    require(msg.value >= DEPOSIT,'Not enough deposit to deploy car');           //Initial deposit is needed for guarantees
    carList[_identifier] = car(
        msg.sender,             //Owner
        address(0),             //Renter, initialized 0
        address(0),             //Car hardware address
        0,                      //Initialize contract step --> secure programming best practice
        _pricePerHour,
        now,                    //driveStartTime, exact time not that important here
        _accessToken,
        _location,
        _identifier);

    ownerList[msg.sender] = owner(
        msg.sender, //owner
        msg.value,  //balance
        _ownerName, //name
        _identifier); //carIdentifier

        emit E_deployedCar(msg.sender, _identifier, ownerList[msg.sender].balance);
    }
        
    //1b. If a Renter has a signed proof that he is registered in the system and has put a deposit, he is entered inside the system.
    //Question: How should this proof look like to be a valid proof coupled to a specific user? Require proofIsValidFunction
    function enterRenter(bytes32 _proof, uint8 _v, bytes32 _r, bytes32 _s) public payable{
        require(msg.value >= DEPOSIT,'Not enough deposit to enter system');
        require(isSignatureValid(REGISTRATION_SERVICE, _proof, _v, _r, _s), 'No valid proof of registration');
        require(renterList[msg.sender].validated == false, 'Renter already in the system'); 
        renterList[msg.sender] = renter(
            msg.sender,
            msg.value,
            _proof,
            true,
            ""
        );
        emit E_registeredRenter(msg.sender, msg.value, _proof);
    }
    
    
    //2 Book a car based on identifier
    function rentCar(string memory _carIdentifier) public returns(bytes memory){
        require(renterList[msg.sender].balance >= DEPOSIT,'Not enough balance, please fund account');
        require(keccak256(abi.encode(renterList[msg.sender].carIdentifier)) == keccak256(""), 'Please return previous car');
        require(carList[_carIdentifier].contractStep == 0, 'Car currently in use, pick other car!');

        carList[_carIdentifier].contractStep++;
        carList[_carIdentifier].driveStartTime = now;

        emit E_carRented(carList[_carIdentifier].owner, carList[_carIdentifier].renter, _carIdentifier, carList[_carIdentifier].accessToken);
        return carList[_carIdentifier].accessToken;

    }
    
    
    //3 End booking, needs to be public, because it can be called by owner/renter
    function endRentCar(string memory _carIdentifier) public involvedParties(carList[_carIdentifier]) {
        car storage _car = carList[_carIdentifier];
        require(_car.contractStep == 1, "Car is not locked");
        uint _fee = (now - _car.driveStartTime) * _car.pricePerBlock;
        ownerList[_car.owner].balance += _fee;
        renterList[_car.renter].balance -= _fee;
        renterList[_car.renter].carIdentifier = "";
        _car.renter = address(0);
        _car.contractStep = 0;                   //Owner deposit needs to be checked
        emit E_endRent(msg.sender, _carIdentifier, _fee);

    }
    
    
    //Check whether registry service has signed off that a renter is allowed to drive the car
    function isSignatureValid(address _address, bytes32 _proof, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool) {
        address _signer = ecrecover(_proof, _v, _r, _s);  //possible some manipulation needed to get proof in proper form...
        return(_signer == _address);
    }

    //Check balance of owner or renter
    function checkBalance(bool _owner) public view returns(uint) {
        if (_owner == true) {
            return ownerList[msg.sender].balance;
        } else {
            return renterList[msg.sender].balance;
        }
    }
    
    //Withdraw Balance
    function withdrawBalance(bool _owner) public{
        if (_owner == true) {
            msg.sender.transfer(ownerList[msg.sender].balance);
        } else {
            msg.sender.transfer(renterList[msg.sender].balance);
        }
    }
    
    function fundBalance(bool _owner) public payable{
        if (_owner == true) {
            ownerList[msg.sender].balance += msg.value;
        } else {
            renterList[msg.sender].balance += msg.value;
        }
    }
    
    function getCar(string memory _identifier) public view returns(car memory){
        return carList[_identifier];
    }
    
    function getOwner(address  _owner) public view returns (owner memory){
        return ownerList[_owner];
    }
    
    function getRenter(address _renter) public view returns (renter memory){
        return renterList[_renter];
    }


}
