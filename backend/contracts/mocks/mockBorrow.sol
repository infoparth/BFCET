// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract borrowToken is ERC20, ERC20Burnable{

    constructor() ERC20("Borrower", "BRW"){
    }

    function _mintToken(address to, uint256 amount)
    external 
    {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 value) public virtual override{
        _burn(account, value);
    }

}