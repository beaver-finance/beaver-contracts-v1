// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../libraries/RemovableList.sol";

contract MockRemovableListUser {

    RemovableList.Keys internal keys;

    constructor() public {
        //
    }

    function insert(address item) public {
        RemovableList.insert(keys, item);
    }

    function get(uint256 index) public view returns (address) {
        return RemovableList.get(keys, index);
    }

    function len() public view returns (uint256) {
        return RemovableList.len(keys);
    }

    function remove(address item) public {
        RemovableList.remove(keys, item);
    }
}