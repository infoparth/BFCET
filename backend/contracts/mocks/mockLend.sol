// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface xyz {
    function depositCollateral(address, address) external returns (uint256);
}
contract lendingToken is ERC20, ERC20Burnable{

    address public poolAddress;


    constructor() ERC20("Lender", "LNR") {
    }

    function _mintToken(address to, uint256 amount)
    external 
    {
        _mint(to, amount);
    }

    // function transferFrom(address from, address to, uint256 amount)
    // external 
    // virtual override returns(bool){

    //     xyz(poolAddress).depositCollateral(from, to) -= amount;
    //     super.transferFrom(from, to, amount);

    // }

     function burnFrom(address account, uint256 value) public virtual override{
        _burn(account, value);
    }

    function setPoolAdress (address to)
    external 
    {
        poolAddress = to;
    }

}