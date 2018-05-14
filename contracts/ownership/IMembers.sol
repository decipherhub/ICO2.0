pragma solidity ^0.4.23;

contract IMembers {
    enum MEMBER_LEVEL {NONE, PRIV, ADV, DEV, OWNER}
    
    function owner() public view returns(address);
    function isLockedGroup(address addr) public view returns(bool);
    function isDeveloper(address addr) public view returns(bool);
    function getMemberLevel(address addr) public view returns(MEMBER_LEVEL);
    function transferOwnership(address newOwner) public;
    function setCrowdsale(address _saleAddr) public;
    function enroll_developer(address _devAddr) public;
    function enroll_advisor(address _advAddr) public;
    function enroll_privsale(address _privAddr) public;
    function delete_developer(address _devAddr) public;
    function delete_advisor(address _advAddr) public;
    function delete_privsale(address _privAddr) public; 
    
    /* Events */
    event CreateOwnership(address indexed _owner);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event EnrollDeveloper(address indexed _devAddress);
    event EnrollAdvisor(address indexed _advAddress);
    event EnrollPrivsale(address indexed _privAddress);
    event DeleteDeveloper(address indexed _devAddress);
    event DeleteAdvisor(address indexed _advAddress);
    event DeletePrivsale(address indexed _privAddress);
}
