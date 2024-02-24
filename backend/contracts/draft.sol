// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface collateralToken{

    function transferFrom(address from, address to, uint256 amount) 
    external 
    returns(bool);

    function name() external returns(string memory);

}

interface IDIAOracleV2
{
    function getValue(string memory) external returns (uint128, uint128);
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

    error CollateralDepositionFailed();
    error BreaksHealthFactor(uint256);

    event CollateralDeposited(address indexed tokenAddress, address indexed user);
    event CollateralAdded(address indexed tokenAddress);
    event CollateralRemoved(address indexed tokenAddress);

    modifier moreThanZero(uint256 amount){

        require(amount > 0, "Amount needs to be more than zero");
        _;

    }

    modifier isAllowedToken(address _token){
        require(allowedCollateralTokens[_token] != 0, "Token address is allowed");
        _;
    }

    uint256 private constant LIQUIDATION_THRESHOLD = 80;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public tokenThreshold; //The threshold value for the RWA tokens
    uint256 public recievedValue;  //The recived USD value from the oracle
    address public oracleAddress; //stpres the oracle address
    uint256 public latestPrice;  //stores the latest price fetched from the oracle

    mapping (address => uint256) public allowedCollateralTokens;

    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    
    mapping (address => uint256 amount) private s_BorrowAmount;

    //////////////////// 
    /// Constructor ///
    ///////////////////

    constructor(address _owner)Ownable(_owner)
    {}

    //////////////////////////
    /// External Functions///
    /////////////////////////

    function depositCollateralAndLend(address pool, address token, address user, uint256 amount)
    external
    moreThanZero(amount)
    isAllowedToken(token)
    {
        depositCollateral(token, amount, user);
        ILendingPool(pool).deposit(token, amount, user, 0);
    }

    function depositCollateralAndBorrowToken(address pool, address token, address user, uint256 amount, uint256 rateMode)
    external
    moreThanZero(amount) 
    isAllowedToken(token)
    {
        s_BorrowAmount[user] += amount;
        revertIfHealthFactorIsBroken(user, token);
        depositCollateral(token, amount, user);
        ILendingPool(pool).borrow(token, amount, rateMode, 0, user);
    }

    function addCollateralToken(address _newAddress, uint256 thresholdAmount)
    external
    onlyOwner
    {
        allowedCollateralTokens[_newAddress] = thresholdAmount;
        emit CollateralAdded(_newAddress);
    }

    function removeCollateralToken(address _newAddress)
    external
    onlyOwner
    {
        delete allowedCollateralTokens[_newAddress];
        emit CollateralRemoved(_newAddress);
    }

    function changeOracleAddress(address _newAddress)
    external
    onlyOwner{
        oracleAddress = _newAddress;
    }

    ///////////////////////////
    /// Internal Functions ///
    //////////////////////////

    function depositCollateral(address _tokenAddress, uint256 amountToken, address _user)
    internal
    {
        bool success = collateralToken(_tokenAddress).transferFrom(msg.sender, address(this), amountToken);
        s_collateralDeposited[_user][_tokenAddress] = amountToken;
        if(!success){
            revert CollateralDepositionFailed();
        }
        emit CollateralDeposited(_tokenAddress, _user);
    }


    //////////////////////////////////////////////////
    /// Private & Internal View && Pure functions ///
    /////////////////////////////////////////////////\

    function getUSDValue(address _token)
    private
    returns(uint256)
    {
        string memory tokenName = collateralToken(_token).name();
        string memory key = string.concat(tokenName, "/USD");
        (latestPrice, ) = IDIAOracleV2(oracleAddress).getValue(key);
        return latestPrice;
    }


    function getCollateralValueOfUser(address _token, address _user)
    private 
    returns(uint256 borrowAmount, uint256 userCollateralValue)
    {
        borrowAmount = s_BorrowAmount[_user];
        userCollateralValue = getUSDValue(_token);
    }

    function _calculateHealthFactor(uint256 totalBorrowed, uint256 collateralValueInUSD)
    private
    pure
    returns(uint256)
    {
        if(totalBorrowed == 0) 
        {
            return type(uint256).max;
        }
        uint256 collateralAdjustedForThreshold = (collateralValueInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalBorrowed; 

    }

    function _healthFactor(address collateralAddress, address user)
    private
    returns(uint256){
        (uint256 totalBorrowed, uint256 collateralValueInUsd) = getCollateralValueOfUser(collateralAddress, user);
        return  _calculateHealthFactor(totalBorrowed, collateralValueInUsd);
    }

    function revertIfHealthFactorIsBroken(address user, address _collateralToken)
    private
    {
        uint256 userHealthFactor = _healthFactor(_collateralToken, user);
        if(userHealthFactor < MIN_HEALTH_FACTOR)
        {
            revert BreaksHealthFactor(userHealthFactor);
        }

    }


}