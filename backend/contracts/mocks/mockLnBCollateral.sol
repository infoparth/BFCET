// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IDIAOracleV2
{
    function getValue(string memory) external view returns (uint128, uint128);
}


contract collateralLnB is ERC20{

    uint256 public all;

    constructor() ERC20("Test_Collateral", "TSC"){
    }

    function _mintToken(address to, uint256 amount)
    external 
    {
        _mint(to, amount);
    }

     function decimals() public view virtual override returns (uint8) {
        return 10;
    }

}