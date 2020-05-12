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

contract carSharing{

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

    /*Phase 2: After driving is finished they change their state on-chain, car publishes fee on-chain -> happens off-chain
    function renterEnd(bytes32 _preimage, bytes32 _newLock, uint _fee) public renterBooked() {
        require(renter_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        require(_fee > 0, 'invalid fee, check through range proof');
        renter_hashLock[msg.sender] = _newLock;
        renter_fee[msg.sender] = _fee;
        renterFees.push(_fee);               //Issue here that it is appended at the end
        emit E_renterEnd(msg.sender, _newLock, _blindedFee);
    }

    function carEnd(bytes32 _preimage) public carBooked() {
        require(car_hashLock[msg.sender] == keccak256(abi.encodePacked(_preimage)), 'Not the appropriate value to open lock');
        uint _fee = (now - car_start[msg.sender])*car_price[msg.sender];    //Fee calculation happens at car side
        carFees.push(keccak256(abi.encodePacked(_fee)));                  //Issue here that it is appended at the end
        emit E_carEnd(msg.sender, _fee);
    }*/

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

    //Dispute resolution dissolves privacy



    //Check whether correct address has signed off a certain hashed value
    function isSignatureValid(address _address, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool) {
        address _signer = ecrecover(_hash, _v, _r, _s);
        return(_signer == _address);
    }   
}

contract verifyRingSignature{
    mapping(uint256 => bool) KeyImageUsed;
    
    function Verify(address[] destination, uint256[] value, uint256[] signature)
        public returns (bool success)
    {
        //Check Array Bounds
        require(destination.length == value.length);
        
        //Check for new key Image
        require(!KeyImageUsed[signature[0]]);
        
        //Get Ring Size
        uint256 ring_size = (signature.length - 2) / 2;
        
        //Check Values of Addresses - Must Match
        uint256 i;
        address addr;
        uint256 txValue;
        uint256 temp;
        for (i = 0; i < ring_size; i++) {
            temp = signature[2+ring_size+i];
            addr = GetAddress(temp);
            
            //On first i, fetch value
            if (i == 0) {
                txValue = token_balance[addr];
            }
            //Values must match first address
            else {
                require(txValue == token_balance[addr]);
            }
            
            //Update Lookup By Balance Table for Convenient Mix-ins
            if (!lookup_pubkey_by_balance_populated[temp]) {
                lookup_pubkey_by_balance[txValue].push(temp);
                lookup_pubkey_by_balance_populated[temp] = true;
                lookup_pubkey_by_balance_count[txValue]++;
            }
        }
        
        //Verify that the value to be sent spends the exact amount
        temp = 0;
        for (i = 0; i < value.length; i++) {
            if (value[i] > txValue) return false; //Check for crafty overflows
            temp += value[i];
        }
        if (temp != txValue) return false;
        
        //Check Ring for Validity
        success = RingVerify(RingMessage(destination, value), signature);
        
        //Pay out balance
        if (success) {
            KeyImageUsed[signature[0]] = true;
            for (i = 0; i < destination.length; i++) {
                destination[i].transfer(value[i]);
            }
        }
    }
    
    //Address Functions - Convert compressed public key into RingMixer address
    function GetAddress(uint256 PubKey)
        public view returns (address addr)
    {
        uint256[2] memory temp;
        temp = ExpandPoint(PubKey);
        addr = address( keccak256(temp[0], temp[1]) );
    }
    
    //Base EC Functions
    function ecAdd(uint256[2] p0, uint256[2] p1)
        public view returns (uint256[2] p2)
    {
        assembly {
            //Get Free Memory Pointer
            let p := mload(0x40)
            
            //Store Data for ECAdd Call
            mstore(p, mload(p0))
            mstore(add(p, 0x20), mload(add(p0, 0x20)))
            mstore(add(p, 0x40), mload(p1))
            mstore(add(p, 0x60), mload(add(p1, 0x20)))
            
            //Call ECAdd
            let success := call(sub(gas, 2000), 0x06, 0, p, 0x80, p, 0x40)
            
            // Use "invalid" to make gas estimation work
 			switch success case 0 { revert(p, 0x80) }
 			
 			//Store Return Data
 			mstore(p2, mload(p))
 			mstore(add(p2, 0x20), mload(add(p,0x20)))
        }
    }
    
    function ecMul(uint256[2] p0, uint256 s)
        public view returns (uint256[2] p1)
    {
        assembly {
            //Get Free Memory Pointer
            let p := mload(0x40)
            
            //Store Data for ECMul Call
            mstore(p, mload(p0))
            mstore(add(p, 0x20), mload(add(p0, 0x20)))
            mstore(add(p, 0x40), s)
            
            //Call ECAdd
            let success := call(sub(gas, 2000), 0x07, 0, p, 0x60, p, 0x40)
            
            // Use "invalid" to make gas estimation work
 			switch success case 0 { revert(p, 0x80) }
 			
 			//Store Return Data
 			mstore(p1, mload(p))
 			mstore(add(p1, 0x20), mload(add(p,0x20)))
        }
    }
    
    function CompressPoint(uint256[2] Pin)
        public pure returns (uint256 Pout)
    {
        //Store x value
        Pout = Pin[0];
        
        //Determine Sign
        if ((Pin[1] & 0x1) == 0x1) {
            Pout |= ECSignMask;
        }
    }
    
    function EvaluateCurve(uint256 x)
        public constant returns (uint256 y, bool onCurve)
    {
        uint256 y_squared = mulmod(x,x, P);
        y_squared = mulmod(y_squared, x, P);
        y_squared = addmod(y_squared, 3, P);
        
        uint256 p_local = P;
        uint256 a_local = a;
        
        assembly {
            //Get Free Memory Pointer
            let p := mload(0x40)
            
            //Store Data for Big Int Mod Exp Call
            mstore(p, 0x20)                 //Length of Base
            mstore(add(p, 0x20), 0x20)      //Length of Exponent
            mstore(add(p, 0x40), 0x20)      //Length of Modulus
            mstore(add(p, 0x60), y_squared) //Base
            mstore(add(p, 0x80), a_local)   //Exponent
            mstore(add(p, 0xA0), p_local)   //Modulus
            
            //Call Big Int Mod Exp
            let success := call(sub(gas, 2000), 0x05, 0, p, 0xC0, p, 0x20)
            
            // Use "invalid" to make gas estimation work
 			switch success case 0 { revert(p, 0xC0) }
 			
 			//Store Return Data
 			y := mload(p)
        }
        
        //Check Answer
        onCurve = (y_squared == mulmod(y, y, P));
    }
    
    function ExpandPoint(uint256 Pin)
        public constant returns (uint256[2] Pout)
    {
        //Get x value (mask out sign bit)
        Pout[0] = Pin & (~ECSignMask);
        
        //Get y value
        bool onCurve;
        uint256 y;
        (y, onCurve) = EvaluateCurve(Pout[0]);
        
        //TODO: Find better failure case for point not on curve
        if (!onCurve) {
            Pout[0] = 0;
            Pout[1] = 0;
        }
        else {
            //Use Positive Y
            if ((Pin & ECSignMask) != 0) {
                if ((y & 0x1) == 0x1) {
                    Pout[1] = y;
                } else {
                    Pout[1] = P - y;
                }
            }
            //Use Negative Y
            else {
                if ((y & 0x1) == 0x1) {
                    Pout[1] = P - y;
                } else {
                    Pout[1] = y;
                }
            }
        }
    }
    
}
