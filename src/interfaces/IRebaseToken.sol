// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

interface IRebaseToken {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function balanceOf(address user) external returns (uint256);
}
