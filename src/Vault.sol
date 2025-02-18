// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";
/**
 * @author inukaG
 * @dev this is contract for deposit widthdrw eth from users and recieveing rewards
 * mint same amount token as eth deposited
 * burn tokens send eth when redeem
 *
 */

contract Vault {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IRebaseToken private immutable i_rebaseToken;

    error Vault__redeemNotSuccess();

    event Deposited(address index, uint256);
    event Redeemed(address index, uint256);

    constructor(IRebaseToken rebaseToken) {
        i_rebaseToken = rebaseToken;
    }
    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit() public payable {
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    function redeem(uint256 amount) public {
        if (amount == type(uint256).max) {
            amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burn(msg.sender, amount);
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert Vault__redeemNotSuccess();
        }
        emit Redeemed(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getRebaseTokenAddress() public view returns (address) {
        return address(i_rebaseToken);
    }

    receive() external payable {}
}
