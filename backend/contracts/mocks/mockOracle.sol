// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract testOracle{

    uint128 amount = 100000000;

    uint128 amount2 = 4543435;

    uint256 constant testu = 1e10;

    constructor(){}

    function getValue(string memory test) 
    external 
    view
    returns(uint128, uint128)
    {
        return (amount, amount2);
    }
}