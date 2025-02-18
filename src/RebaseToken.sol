// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @author inukaG
 * @notice interest rate in smart contract can only decrease
 * @notice users have their own interest rated based on global interest rate
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__interestRate_High(uint256, uint256);

    event RebaseToken__interestRateSet(uint256);
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_BURN_ROLE = keccak256("mint_burn");
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) s_addressToInterestRate;
    mapping(address => uint256) s_userLastUpdatedTimeStamp;

    constructor() ERC20("Axion Rebase", "RAXN") Ownable(msg.sender) {}
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function grantRoleForMintAndBurn(address user) external onlyOwner {
        _grantRole(MINT_BURN_ROLE, user);
    }

    function setInterestRate(uint256 interestRate) external onlyOwner {
        //only can decrease the interest rate
        if (interestRate > s_interestRate) revert RebaseToken__interestRate_High(interestRate, s_interestRate);
        s_interestRate = interestRate;
        emit RebaseToken__interestRateSet(interestRate);
    }

    function balanceOf(address user) public view override returns (uint256) {
        if (super.balanceOf(user) == 0) {
            return 0;
        }
        return (super.balanceOf(user) * _calculateAccumilatedInterestSinceLastTimeStamp(user)) / PRECISION_FACTOR;
    }

    function mint(address to, uint256 amount) public onlyRole(MINT_BURN_ROLE) {
        _mintAccuredInterest(to);
        s_addressToInterestRate[to] = s_interestRate;
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(MINT_BURN_ROLE) {
        // miitigate dust
        if (amount == type(uint256).max) {
            amount = balanceOf(from);
        }
        _mintAccuredInterest(from);
        _burn(from, amount);
    }

    function transfer(address reciepient, uint256 amount) public override returns (bool) {
        _mintAccuredInterest(msg.sender);
        _mintAccuredInterest(reciepient);
        if (amount == type(uint256).max) {
            amount = balanceOf(msg.sender);
        }
        if (balanceOf(reciepient) == 0) {
            s_addressToInterestRate[reciepient] = s_addressToInterestRate[msg.sender];
        }
        return super.transfer(reciepient, amount);
    }

    function transferFrom(address sender, address reciepient, uint256 amount) public override returns (bool) {
        _mintAccuredInterest(sender);
        _mintAccuredInterest(reciepient);
        if (amount == type(uint256).max) {
            amount = balanceOf(sender);
        }
        if (balanceOf(reciepient) == 0) {
            s_addressToInterestRate[reciepient] = s_addressToInterestRate[sender];
        }
        return super.transferFrom(sender, reciepient, amount);
    }
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _calculateAccumilatedInterestSinceLastTimeStamp(address _user) internal view returns (uint256) {
        uint256 timeDifference = block.timestamp - s_userLastUpdatedTimeStamp[_user];
        return PRECISION_FACTOR + (s_addressToInterestRate[_user] * timeDifference);
    }

    function _mintAccuredInterest(address _user) internal {
        // 1. get current balance of rebase tokens-> priciple balance
        // 2. get total amount to get after interest use balanceOf()func
        // 3. mint interest
        uint256 previousBalance = super.balanceOf(_user);
        uint256 newBalance = balanceOf(_user);
        uint256 amountTobeMinted = newBalance - previousBalance;
        s_userLastUpdatedTimeStamp[_user] = block.timestamp;
        _mint(_user, amountTobeMinted);
    }
    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getUserCurrentInterestRate(address user) public view returns (uint256) {
        return s_addressToInterestRate[user];
    }
    // currently minited tokens not included interest

    function getPrincipalBalanceOf(address user) public view returns (uint256) {
        return super.balanceOf(user);
    }

    function getCurrentInterestRate() public view returns (uint256) {
        return s_interestRate;
    }
}
