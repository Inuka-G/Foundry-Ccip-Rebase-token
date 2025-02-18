// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {Vault} from "src/Vault.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    RebaseToken rebaseToken;
    Vault vault;

    function setUp() public {
        vm.startPrank(owner);
        vm.deal(owner, 20e18);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        (bool success,) = payable(address(vault)).call{value: 2e18}("");
        console.log(success);
        rebaseToken.grantRoleForMintAndBurn(address(vault));
        vm.stopPrank();
    }

    function testDepositLinear(uint256 amount) public {
        // amount = bound(amount, 1e5, type(uint96).max);
        // vm.startPrank(user);
        // vm.deal(user, amount * 2);

        // vault.deposit{value: amount}();
        // uint256 firstBalance = rebaseToken.balanceOf(user);
        // console.log(firstBalance);
        // vm.warp(block.timestamp + 1 hours);
        // uint256 secondBalance = rebaseToken.balanceOf(user);
        // assertGt(secondBalance, firstBalance);
        // console.log(secondBalance);
        // vm.warp(block.timestamp + 1 hours);
        // uint256 thirdBalance = rebaseToken.balanceOf(user);
        // console.log(thirdBalance);
        // assertGt(thirdBalance, secondBalance);
        // assertApproxEqAbs(thirdBalance - secondBalance, secondBalance - firstBalance, 1);
        // vm.stopPrank();
        // Deposit funds
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        // 2. check our rebase token balance
        uint256 startBalance = rebaseToken.balanceOf(user);
        console.log("getUserCurrentInterestRate", rebaseToken.getUserCurrentInterestRate(user));
        console.log("block.timestamp", block.timestamp);
        console.log("startBalance", startBalance);
        assertEq(startBalance, amount);
        // 3. warp the time and check the balance again
        vm.warp(block.timestamp + 1 hours);
        console.log("block.timestamp", block.timestamp);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        console.log("middleBalance", middleBalance);
        assertGt(middleBalance, startBalance);
        // 4. warp the time again by the same amount and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);
        console.log("block.timestamp", block.timestamp);
        console.log("endBalance", endBalance);
        console.log("getUserCurrentInterestRate", rebaseToken.getUserCurrentInterestRate(user));
        assertGt(endBalance, middleBalance);

        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);

        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        vault.redeem(type(uint256).max);
        console.log("", rebaseToken.balanceOf(user));
        console.log(user.balance);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(user.balance, amount);
        vm.stopPrank();
    }
}
