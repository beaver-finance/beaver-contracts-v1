pragma solidity >=0.6.12;

import "../libraries/IterableMapping.sol";

contract MockIterableMappingUser {

    IterableMapping.Keys internal testIter;

    constructor() public {
        //
    }

    function insert() public returns (uint256) {
        return IterableMapping.insert(testIter);
    }

    function get(uint256 index) public view returns (uint256) {

        return IterableMapping.get(testIter, index);
    }

    function len() public view returns (uint256) {

        return IterableMapping.len(testIter);
    }
}