pragma solidity ^0.5;

contract PKI{
    mapping(address => uint) pks;
    mapping(address => bool) hasAnnounced;

    modifier notAnounced() public {
        require(hasAnnounced[msg.sender] = false);
        _;
    }

    function announcePk(uint pk) notAnnounced() public {
        pks[msg.sender] = pk;
        hasAnnounced[msg.sender] = true;
    }

    function getPk(address a) public view returns(uint) {
        require(hasAnnounced[a]);  
        return pks[a];
    }
}
