pragma solidity ^0.5;

contract PKI{
    mapping(address => uint)    pkZkay;         //Public Keys for use with zkay are stored in this mapping
    mapping(address => bool)    hasAnnounced;
    mapping(address => uint[5]) pkRingSign;     //Possible Public Keys tied to an Ethereum address. Each key can be used for one booking.

    function announcePkZk(uint pk) public {
        pkZkay[msg.sender] = pk;
        hasAnnounced[msg.sender] = true;
    }

    function getPk(address a) public view returns(uint) {
        require(hasAnnounced[a]);  
        return pkZkay[a];
    }

    function announcePkRingSign(uint[5] memory pks) public {
        pkRingSign[msg.sender] = pks;
        hasAnnounced[msg.sender] = true;
    }

    function getPkRingSign(address a) public view returns(uint[5] memory) {
        return pkRingSign[a];
    }
}
