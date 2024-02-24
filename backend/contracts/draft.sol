// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface collateralToken{

    function transferFrom(address from, address to, uint256 amount) 
    external 
    virtual
    returns(bool);

}

interface ILendingPool{

    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

   function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

    function getUserConfiguration(address user)
    external
    view
    returns (uint256);
}

contract draft is Ownable {

    modifier moreThanZero(uint256 amount){

        require(amount > 0, "Amount needs to be more than zero");
        _;

    }

    modifier isAllowedToken(address _token){
        require(allowedCollateralTokens[_token] != 0, "Token address is allowed");
        _;
    }

    uint256 public tokenThreshold; //The threshold value for the RWA tokens
    uint256 public recievedValue;  //The recived USD value from the oracle

    mapping (address => uint256) public allowedCollateralTokens;

    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    
    mapping (address => uint256 amount) private s_BorrowAmount;



    constructor(address _owner)Ownable(_owner)
    {}

    function depositCollateral(address _tokenAddress, uint256 amountToken)
    external
    moreThanZero(amountToken)
    isAllowedToken(_tokenAddress)
    {
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

    function addCollateralToken(address _newAddress, uint256 thresholdAmount)
    external
    onlyOwner
    {
        allowedCollateralTokens[_newAddress] = thresholdAmount;
    }

    function removeCollateralToken(address _newAddress)
    external
    onlyOwner
    {
        delete allowedCollateralTokens[_newAddress];
    }
    }