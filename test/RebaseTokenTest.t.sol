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

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        time = bound(time, 1, 1e5);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        vm.prank(user);
        vm.deal(user, depositAmount);
        vault.deposit{value: depositAmount}();
        vm.warp(block.timestamp + time);
        console.log(rebaseToken.balanceOf(user) - depositAmount);
        uint256 balance = rebaseToken.balanceOf(user);
        vm.prank(owner);
        vm.deal(owner, (rebaseToken.balanceOf(user)));
        payable(address(vault)).call{value: (rebaseToken.balanceOf(user) - depositAmount)}("");
        vm.prank(user);
        vault.redeem(type(uint256).max);
        assertEq(user.balance, balance);
    }

    function testTransferInterestRate(uint256 amount) public {
        amount = bound(amount, 1e8, type(uint96).max);
        address user2 = address(5);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        uint256 prevInterestRate = rebaseToken.getUserCurrentInterestRate(owner);
        vm.prank(owner);
        rebaseToken.setInterestRate(12);
        vm.prank(user);
        rebaseToken.transfer(user2, amount / 3);
        uint256 userBalanceAfterTransfer = rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterTransfer = rebaseToken.balanceOf(user2);
        console.log("1", "2", userBalanceAfterTransfer, user2BalanceAfterTransfer);
        assertEq(amount - userBalanceAfterTransfer, user2BalanceAfterTransfer);
        uint256 user2InterestRate = rebaseToken.getUserCurrentInterestRate(user2);
        uint256 userInterestRate = rebaseToken.getUserCurrentInterestRate(user);
        assert(user2InterestRate != 12);
        assertEq(user2InterestRate, userInterestRate);
    }

    function testUserCannotSetInterestRAte(uint256 interestRAte) public {
        vm.prank(user);
        vm.expectRevert();
        rebaseToken.setInterestRate(interestRAte);
    }

    function testUserCannotCallMint() public {
        vm.prank(user);
        vm.expectRevert();
        rebaseToken.mint(user, 12);
    }

    function testUserCannotCallBurn() public {
        vm.prank(user);
        vm.expectRevert();
        rebaseToken.burn(user, 12);
    }

    function testGetPriciplebalanceOf(uint256 amount) public {
        amount = bound(amount, 1e5, 1005e9);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.getPrincipalBalanceOf(user), amount);

        vm.warp(amount);
        assertEq(rebaseToken.getPrincipalBalanceOf(user), amount);
    }

    function testGetRebaseTokenAddress() public {
        assertEq(vault.getRebaseTokenAddress(), address(rebaseToken));
    }

    function testNewInterestRAteShouldBeBelow(uint256 rate) public {
        uint256 iniRate = rebaseToken.getCurrentInterestRate();
        rate = bound(rate, rebaseToken.getCurrentInterestRate() + 1, rebaseToken.getCurrentInterestRate() + 1e14);
        vm.prank(owner);
        vm.expectRevert();
        rebaseToken.setInterestRate(rate);
        assertEq(rebaseToken.getCurrentInterestRate(), iniRate);
    }
}
