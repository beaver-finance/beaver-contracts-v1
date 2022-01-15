// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

library IterableMapping {
    struct Keys {
        uint256[] keys;
        uint256 id;
    }

    function insert(Keys storage self) public returns (uint256 _id) {
        self.id = self.id + 1;
        _id = self.id;
        self.keys.push(_id);
    }

    function get(Keys storage self, uint256 index) public view returns (uint256) {
        return self.keys[index];
    }

    function len(Keys storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function remove(Keys storage self, uint256 key) public {
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
