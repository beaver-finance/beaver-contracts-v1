// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

library RemovableList {
    struct Keys {
        address[] keys;
    }

    function insert(Keys storage self, address item) public {
        self.keys.push(item);
    }

    function get(Keys storage self, uint256 index) public view returns (address) {
        return self.keys[index];
    }

    function len(Keys storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function remove(Keys storage self, address key) public {
        uint256 indexToBeDeleted;
        uint256 i;
        uint256 arrayLength = self.keys.length;
        for (i = 0; i < arrayLength; i++) {
            if (self.keys[i] == key) {
                indexToBeDeleted = i;
                break;
            }
        }
        if (i >= arrayLength) {
            return;
        }
        if (indexToBeDeleted < arrayLength - 1) {
            self.keys[indexToBeDeleted] = self.keys[arrayLength - 1];
        }
        self.keys.pop();
    }
}
