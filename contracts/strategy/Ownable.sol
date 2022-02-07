// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

contract Ownable is BoringOwnable {
    mapping(address => bool) internal calls;
    mapping(address => bool) internal keepers;

    modifier onlyCaller() {
        require(calls[msg.sender], "caller required");
        _;
    }

    modifier onlyKeeper() {
        require(keepers[msg.sender], "keeper required");
        _;
    }

    function addCaller(address _caller) public onlyOwner {
        _addCaller(_caller);
    }
    
    function setCaller(address _caller, bool _on) public onlyOwner {
        //_setCaller(_caller, _on);
    }

    function _addCaller(address _caller) internal {
        calls[_caller] = true;
    }

    function _setCaller(address _caller, bool _on) internal {
        calls[_caller] = _on;
        if (!_on) {
            delete calls[_caller];
        }
    }


    function addKeeper(address _keeper) public onlyOwner {
        _addKeeper(_keeper);
    }

    function setKeeper(address _keeper, bool _on) public onlyOwner {
        //_setKeeper(_keeper, _on);
    }

    function _addKeeper(address _keeper) internal {
        keepers[_keeper] = true;
    }

    function _setKeeper(address _keeper, bool _on) internal {
        keepers[_keeper] = _on;
        if (!_on) {
            delete keepers[_keeper];
        }
    }

    function isKeeper(address _owner) public view returns (bool) {
        return keepers[_owner];
    }
}
