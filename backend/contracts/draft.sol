// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {ILendingPool} from "@starlay-finance/starlay-protocol/contracts/interfaces/ILendingPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface collateralToken is Ownable{

    function transferFrom(address from, address to, uint256 amount) 
    external 
    virtual
    returns(bool);

}

contract draft {

    modifier moreThanZero(uint256 amount){

        requrie(amount > 0, "Amount needs to be more than zero");
        _;

    }

    modifier isAllowedToken(address _token){
        requrie(allowedCollateralTokens[_token] == true, "Token address is allowed");
        _;
    }

    mapping (address => bool) public allowedCollateralTokens;

    constructor()
    {}

    function depositCollateral(address _tokenAddress, uint256 amountToken)
    external
    moreThanZero(amountToken)
    isAllowedToken(_tokenAddress){

        bool success = collateralToken(_tokenAddress).transferFrom(msg.sender, address(this), amountToken);
    }

    function depositToken(address pool, address token, address user, uint256 amount)
    external
    moreThanZero(amount)
    {
        ILendingPool(pool).deposit(token, amount, user, 0);
    }

    function borrowToken(address pool, address token, address user, uint256 amount, uint256 rateMode)
    external
    moreThanZero(amount) 
    {
        ILendingPool(pool).borrow(token, amount, rateMode, 0, user);
    }

    function addCollateralToken(address _newAddress)
    onlyOwner
    {

    }
    }