// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@boringcrypto/boring-solidity/contracts/ERC20.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

contract BeaverERC20 is ERC20 {
    uint256 public totalSupply;

    string public name;

    function symbol() external view returns (string memory) {
        return name;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    constructor(string memory _name) public {
        name = _name;
    }

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}
