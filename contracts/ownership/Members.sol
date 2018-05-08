pragma solidity ^0.4.23;

contract Members {
    enum MEMBER_LEVEL {NONE, LOCKED, DEV, OWNER}

    address owner_;
    mapping(address => MEMBER_LEVEL) memberLevel;

    event CreateOwnership(address indexed _owner);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event EnrollLockedGroup(address indexed _crowdsaleAddr, address indexed _presaleAddr);
    event EnrollDeveloper(address indexed _owner, address indexed _devAddress);
    event DeleteDeveloper(address indexed _owner, address indexed _devAddress);

    modifier onlyOwner() {
        require(msg.sender == owner_, "Not Owner");
        _;
    }

    modifier only(address addr) {
        require(msg.sender != 0x0);
        require(msg.sender == addr, "Not corresponding address");
        _;
    }

    constructor() public {
        owner_ = msg.sender;
        emit CreateOwnership(owner_);
        memberLevel[owner_] = MEMBER_LEVEL.OWNER;
    }

    function owner() public view
        returns(address) {
            return owner_;
    }

    function isLockedGroup(address addr) public view
        returns(bool) {
            return (uint(memberLevel[addr]) > uint(MEMBER_LEVEL.NONE));
    }

    function isDeveloper(address addr) public view
        returns(bool) {
            return (uint(memberLevel[addr]) > uint(MEMBER_LEVEL.LOCKED));
    }

    function transferOwnership(address newOwner) public
        onlyOwner {
            require(newOwner != 0x0);
            require(isDeveloper(newOwner), "Not Developers");
            emit OwnershipTransferred(owner_, newOwner);
            memberLevel[newOwner] = MEMBER_LEVEL.OWNER;
            memberLevel[owner_] = MEMBER_LEVEL.LOCKED; //FIXIT
            owner_ = newOwner;
    }

    function enroll_presale(address addr) public
        //only(crowdsale_address) { // FIXIT: is it possible?
    {
            require(addr != 0x0);
            require(!isLockedGroup(addr), "It is already in locked group");
            emit EnrollLockedGroup(msg.sender, addr);
            memberLevel[addr] = MEMBER_LEVEL.LOCKED;
    }

    function enroll_developer(address dev_addr) public
        onlyOwner {
            require(dev_addr != 0x0);
            require(!isDeveloper(dev_addr), "It is developer");
            emit EnrollDeveloper(msg.sender, dev_addr);
            memberLevel[dev_addr] = MEMBER_LEVEL.DEV;
    }

    function delete_developer(address dev_addr) public
        onlyOwner {
            require(dev_addr != 0x0);
            require(dev_addr != owner_, "Must not be self-destruct");
            require(isDeveloper(dev_addr), "Not Developers");
            emit DeleteDeveloper(msg.sender, dev_addr);
            memberLevel[dev_addr] = MEMBER_LEVEL.LOCKED; // FIXIT
    }
}
