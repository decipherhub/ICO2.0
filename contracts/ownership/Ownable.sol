pragma solidity ^0.4.23;

import "./IMembers.sol";

contract Ownable {
    IMembers public members;

    /* CONSTRUCTOR */
    constructor(address _membersAddress) public {
        require(_membersAddress != 0x0);
        members = IMembers(_membersAddress);
    }

    /*MODIFIER*/
    modifier only(address account) {
        require(msg.sender != 0x0);
        require(msg.sender == account);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == members.owner());
        _;
    }

    modifier onlyDevelopers() {
        require(members.isDeveloper(msg.sender));
        _;
    }
    
    function isOwner(address account) public view
        returns(bool) {
            return (account == members.owner());
    }

    function isDeveloper(address account) public view
        returns(bool) {
            return members.isDeveloper(account);
    }

    function isLockedGroup(address account) public view
        returns(bool) {
            return members.isLockedGroup(account);
    }

}
