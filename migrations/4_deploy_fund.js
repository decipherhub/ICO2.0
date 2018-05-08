const IncentivePool = artifacts.require("./IncentivePool.sol");
const ReservePool = artifacts.require("./ReservePool.sol");
const ERC20 = artifacts.require("./ERC20.sol");
const IERC20 = artifacts.require("./IERC20.sol");
const Crowdsale = artifacts.require("./Crowdsale.sol");
const Ownable = artifacts.require("./Ownable.sol");
const Members = artifacts.require("./Members.sol");
const VotingFactory = artifacts.require("./VotingFactory.sol");
const TapVoting = artifacts.require("./TapVoting.sol");
const RefundVoting = artifacts.require("./RefundVoting.sol");
const SafeMath = artifacts.require("./SafeMath.sol");

const Fund = artifacts.require("./Fund.sol");

module.exports = async function(deployer, network, accounts) {
    deployer.deploy(SafeMath);
    deployer.link(SafeMath, Fund);
    //deployer.deploy(Fund, token, teamWallet, membersAddress, {from: accounts[0], gasLimit: 50000000});
    const _token = await ERC20.deployed();
    const _teamWallet = accounts[4];
    const _membersAddress = await Members.deployed();
    deployer.deploy(Fund, _token.address, _teamWallet, _membersAddress.address, {from: accounts[0], gasLimit: 50000000});
};
