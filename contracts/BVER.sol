// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol"; 

contract BVER is ERC20Capped {  
  address public governance;
  mapping (address => bool) public minters;
  
  modifier onlyGovernance() {
      require(msg.sender == governance, "!governance");
      _;
  }

  modifier onlyMinter() {
      require(minters[msg.sender], "!minter");
      _;
  }

  constructor (address _governance) 
    ERC20("beaver.finance", "BVER") 
    ERC20Capped(1e9 * 1 ether) {
      governance = _governance;
  }

  function mint(address account, uint amount) public onlyMinter {
      super._mint(account, amount);
  }
  
  function setGovernance(address _governance) public onlyGovernance {
      governance = _governance;
  }
  
  function addMinter(address _minter) public onlyGovernance {
      minters[_minter] = true;
  }
  
  function removeMinter(address _minter) public onlyGovernance {
      minters[_minter] = false;
  }
}
