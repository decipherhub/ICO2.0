pragma solidity ^0.4.23;

import "../ownership/IMembers.sol";

contract Members is IMembers {
    /* 
        Remember we seperated accounts,
        so it should never receive duplicated address
    */

    address owner_;
    address mCrowdsaleAddress;
    mapping(address => MEMBER_LEVEL) mMemberLevel;

    address[] mDevelopers; // we should define owner is a member of dev
    address[] mAdvisors;
    address[] mPrivsale;

    /* Modifier */
    modifier onlyOwner() {
        require(msg.sender == owner_, "Not Owner");
        _;
    }

    modifier only(address addr) {
        require(msg.sender != address(0));
        require(msg.sender == addr, "Not corresponding address");
        _;
    }



    /* Functions */
    // Constructor
    constructor() public {
            owner_ = msg.sender;
            emit CreateOwnership(owner_);
            mMemberLevel[owner_] = MEMBER_LEVEL.OWNER;
            mDevelopers.push(owner_);
    }


    // View functions
    function owner() public view
        returns(address) {
            return owner_;
    }

    function isLockedGroup(address addr) public view
        returns(bool) {
            return (uint(mMemberLevel[addr]) > uint(MEMBER_LEVEL.NONE));
    }

    function isDeveloper(address addr) public view
        returns(bool) {
            return (uint(mMemberLevel[addr]) >= uint(MEMBER_LEVEL.DEV));
    }
    
    function getMemberLevel(address _addr) public view
        returns(MEMBER_LEVEL) {
            return mMemberLevel[_addr];
    }


    // Ownership functions
    function transferOwnership(address newOwner) public
        onlyOwner {
            require(newOwner != address(0));
            require(isDeveloper(newOwner), "Not Developers");

            emit OwnershipTransferred(owner_, newOwner);
            mMemberLevel[newOwner] = MEMBER_LEVEL.OWNER;
            mMemberLevel[owner_] = MEMBER_LEVEL.DEV; // we should define owner is a member of dev
            owner_ = newOwner;
    }


    // Set functions
    function setCrowdsale(address _saleAddr) public
        onlyOwner {
            require(_saleAddr != address(0));
            mCrowdsaleAddress = _saleAddr;
    }

    function enroll_developer(address _devAddr) public
    {
            require(_devAddr != address(0));
            require(!isDeveloper(_devAddr), "It is developer");
            emit EnrollDeveloper(_devAddr);
            mDevelopers.push(_devAddr);
            mMemberLevel[_devAddr] = MEMBER_LEVEL.DEV;
    }

    function enroll_advisor(address _advAddr) public
    {
            require(_advAddr != address(0));
            require(mMemberLevel[_advAddr] != MEMBER_LEVEL.ADV, "It is already in advisor group");
            emit EnrollAdvisor(_advAddr);
            mAdvisors.push(_advAddr);
            mMemberLevel[_advAddr] = MEMBER_LEVEL.ADV;
    }

    function enroll_privsale(address _privAddr) public
    {
            require(_privAddr != address(0));
            require(mMemberLevel[_privAddr] != MEMBER_LEVEL.PRIV, "It is already in privsale group");
            emit EnrollPrivsale(_privAddr);
            mPrivsale.push(_privAddr);
            mMemberLevel[_privAddr] = MEMBER_LEVEL.PRIV;
    }

    function delete_developer(address _devAddr) public
    {
            require(_devAddr != address(0));
            require(mMemberLevel[_devAddr] == MEMBER_LEVEL.DEV);
            emit DeleteDeveloper(_devAddr);
            mMemberLevel[_devAddr] = MEMBER_LEVEL.NONE;
            _reorganizeArray(mDevelopers, _devAddr);
    }

    function delete_advisor(address _advAddr) public
    {
            require(_advAddr != address(0));
            require(mMemberLevel[_advAddr] == MEMBER_LEVEL.ADV);
            emit DeleteAdvisor(_advAddr);
            mMemberLevel[_advAddr] = MEMBER_LEVEL.NONE;
            _reorganizeArray(mAdvisors, _advAddr);
    }
    
    function delete_privsale(address _privAddr) public
    {
            require(_privAddr != address(0));
            require(mMemberLevel[_privAddr] == MEMBER_LEVEL.PRIV);
            emit DeletePrivsale(_privAddr);
            mMemberLevel[_privAddr] = MEMBER_LEVEL.NONE;
            _reorganizeArray(mPrivsale, _privAddr);
    }


    // Internal functions

    // to minimize gas : delete => void = length-1
    function _reorganizeArray(
        address[] storage _array,
        address _deleteAddr) private {
            for(uint i = 0; i < _array.length; i++){
                if(_array[i] == _deleteAddr){
                    _array[i] = _array[_array.length - 1];
                    delete _array[_array.length - 1];
                    _array.length--;
                    break;
                }
            }
    }
}
