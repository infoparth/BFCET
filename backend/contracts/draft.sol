// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface collateralToken{

    function transferFrom(address from, address to, uint256 amount) 
    external 
    returns(bool);

    function symbol() external returns(string memory);

    function balanceOf(address user) external view returns(uint256);

    function decimals() external view returns(uint8);

    function approve(address user, uint256 amount) external returns(bool);

}

interface IDIAOracleV2
{
    function getValue(string memory) external view returns (uint128, uint128);
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

   function withdraw(
    address asset,
    uint256 amount,
    address from,
    address to
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

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external returns(uint256);
}

contract draft is Ownable {

    error CollateralDepositionFailed();
    error BreaksHealthFactor(uint256);
    error CollateralTokenWithdrawFailed();
    error CollateralTokenTransferFailed();
    error CollateralRepayError();
    error CollateralTokenDoesNotExist();
    error InsufficientBalance();
    error DepositTokenDoesNotExist(); 

    event CollateralDeposited(address indexed tokenAddress, address indexed user);
    event CollateralAdded(address indexed tokenAddress);
    event CollateralRemoved(address indexed tokenAddress);
    event CollateralWithdrawn(address indexed tokenAddress, address indexed user);
    event NewDepositTokenAdded(address indexed newDeposit);
    event DepositTokenRemoved(address indexed newDeposit);

    modifier moreThanZero(uint256 amount){

        require(amount > 0, "Amount needs to be more than zero");
        _;

    }

    modifier isAllowedCollateralToken(address _token){
        require(allowedCollateralTokens[_token] != 0, " Collateral token address is allowed");
        _;
    }

    modifier isAllowedDepositToken(address _token){
        require(allowedDepositTokens[_token] != 0, " Deposit token address is not allowed");
        _;
    }

    uint256 private constant LIQUIDATION_THRESHOLD = 80;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant USD_PRECISION = 1e10;
    uint256 public tokenThreshold; //The threshold value for the RWA tokens
    uint256 public recievedValue;  //The recived USD value from the oracle
    address public oracleAddress; //stores the oracle address
    uint256 public latestPrice;  //stores the latest price fetched from the oracle
    address private s_lTokenAddress;
    address public usdcCollateralAddress;

    mapping (address => uint8) public allowedCollateralTokens;

    mapping (address => uint8) public allowedDepositTokens;

    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    
    mapping (address => mapping(address => uint256 amount)) private s_BorrowAmount;

    //////////////////// 
    /// Constructor ///
    ///////////////////

    constructor(address _owner, address _oracleAddress, address l_tokenAddress, address lendingToken, address allowedToken)Ownable(_owner)
    {
        oracleAddress = _oracleAddress;
        s_lTokenAddress = l_tokenAddress;
        uint8 _decimals = collateralToken(allowedToken).decimals();
        allowedCollateralTokens[allowedToken] = _decimals;
        uint8 _lendingDecimals = collateralToken(lendingToken).decimals();
        allowedCollateralTokens[lendingToken] = _lendingDecimals;
        allowedDepositTokens[lendingToken] = _lendingDecimals;
        usdcCollateralAddress = lendingToken;

    }

    //////////////////////////
    /// External Functions///
    /////////////////////////

    /*
     * @dev:Deposit your RWA tokens for lending
     * @param pool: The address of the Lending Pool to deposit collateral 
     * @param tokenToDeposit: The RWA token that is being deposited
     * @param tokenToLend: The colleteral token that is being lent, from the contract
     * @param user: The address of the user, on behalf of whom the token is being lent
     * @param amount: The amount of RWA tokens to deposit
     */
    function depositCollateralAndLend(address pool, address tokenToDeposit, address tokenToLend, address user, uint256 amount)
    external
    moreThanZero(amount)
    isAllowedCollateralToken(tokenToDeposit)
    isAllowedDepositToken(tokenToLend)
    {
        uint256 amountToDeposit = calculateUSDFromRWA(amount, tokenToDeposit, tokenToLend);
        depositCollateral(pool, tokenToDeposit, tokenToLend, amount,amountToDeposit, user);
        uint256 amountToLend = ILendingPool(pool).setUserUseReserveAsCollateral(tokenToLend, true);
    } 

    /*
     * @dev: Deposit your RWA tokens for borrowing
     * @param pool: The address of the Lending Pool to deposit collateral
     * @param tokenToDeposit: The RWA token that is being deposited
     * @param tokenToBorrow: The colleteral token that is being lent, from the contract
     * @param user: The address of the user, on behalf of whom the token is being lent
     * @param amount: The amount of RWA tokens to deposit
     * @param rateMode: The rate mode i.e variable or stable interest
     */
    function depositCollateralAndBorrowToken(address pool,
    address rwaTokenToDeposit, 
    address tokenToBorrow, 
    address user, 
    uint256 amountToDeposit, 
    uint256 amountToBorrow,
    uint256 rateMode)
    external
    moreThanZero(amountToDeposit) 
    isAllowedCollateralToken(rwaTokenToDeposit)
    {
        s_BorrowAmount[user][rwaTokenToDeposit] += amountToBorrow;
        uint256 _amountToDeposit = calculateUSDFromRWA(amountToDeposit, rwaTokenToDeposit, usdcCollateralAddress);
        depositCollateral(pool, rwaTokenToDeposit, usdcCollateralAddress, amountToDeposit, _amountToDeposit, user);
        revertIfHealthFactorIsBroken(user, rwaTokenToDeposit);
        bool _success = collateralToken(usdcCollateralAddress).approve(pool, amountToBorrow);
        ILendingPool(pool).borrow(tokenToBorrow, amountToBorrow, rateMode, 0, user);
    }

    /*
     * @dev: New collateral token to be added by the owner   
     * @param _newAddress: The address of the new token to be added
     */
    function addCollateralToken(address _newAddress)
    external
    onlyOwner
    {
        uint8 _decimals = collateralToken(_newAddress).decimals();
        allowedCollateralTokens[_newAddress] = _decimals;
        emit CollateralAdded(_newAddress);
    }

    /*
     * @dev: New Deposit token to be added by the owner   
     * @param _newAddress: The address of the new token to be added
     */
    function addDepositToken(address _newAddress)
    external
    onlyOwner{
        uint8 _decimals = collateralToken(_newAddress).decimals();
        allowedDepositTokens[_newAddress] = _decimals;
        emit NewDepositTokenAdded(_newAddress);
    }

    /*
     * @dev: Remove a collateral token 
     * @param _address: The address of the token to be removed
     */
    function removeCollateralToken(address _address)
    external
    onlyOwner
    {
        if(allowedCollateralTokens[_address] == 0){
            revert CollateralTokenDoesNotExist();
        }
        delete allowedCollateralTokens[_address];
        emit CollateralRemoved(_address);
    }

    /*
     * @dev: Remove a Deposit token 
     * @param _address: The address of the token to be removed
     */
    function removeDepositToken(address _address)
        external
        onlyOwner
        {
            if(allowedDepositTokens[_address] == 0){
                revert DepositTokenDoesNotExist();
            }
            delete allowedDepositTokens[_address];
            emit DepositTokenRemoved(_address);
        }
        
    /*
     * @dev: Change the Oracle address
     * @param _newAddress: Address of the Oracle
     */
    function changeOracleAddress(address _newAddress)
    external
    onlyOwner
    {
        oracleAddress = _newAddress;
    }

    /*
     * @dev: Repay the Borrowed Token
     * @param pool: Lending pool address 
     * @param asset: The asset being repayed
     * @param amount: The amount of asset being repayed
     * @param rateMode The rate mode, i.e. stable or variable    
     * @param user: The address of the user, who's debt is being repayed
     */
    function repayDebt(address pool, address asset, uint256 amount, uint256 rateMode, address user )
    external
    moreThanZero(amount)
    isAllowedCollateralToken(asset)
    returns(uint256 finalRepay) 
    {
        bool success = collateralToken(asset).transferFrom(msg.sender, address(this), amount);
        if(success){
            collateralToken(asset).approve(pool, amount);
            uint256 payBackAmount = ILendingPool(pool).repay(asset, amount, rateMode, user);
                if(payBackAmount > 0 ){
                    s_BorrowAmount[user][asset] -= finalRepay;
                }
                else{
                    revert CollateralRepayError();
                }
        }
        else{
            revert CollateralTokenTransferFailed(); 
        }
    }

    function withdrawCollateral(address pool, address token, address user, uint256 amount)
    external
    moreThanZero(amount)
    isAllowedCollateralToken(token)

    ///steps to be taken 
    // fetch the totalDepositedCollateral by the user
    // calculate the USD Value of that RWA
    // withdraw that many amount of USDC from the pool, and return that much amount to the draft
    // release that much amount of collateral of the user


    /// withdraw amount should be in USDT and then corresponding number of RWA tokens should be issued
    {

        uint256 _userCollateral = s_collateralDeposited[user][token];
        
        // calculating the USD value of the requested RWA amount
        uint256 _usdValueOfCollateral = calculateUSDFromRWA(amount, token, usdcCollateralAddress);
        // It converts the USD value into the Ltokens Value
        uint256 convertedValue = convertToTokenDecimal(usdcCollateralAddress, s_lTokenAddress, _usdValueOfCollateral);
        // transfers the above amount of lending tokens to this contract
        bool success = collateralToken(s_lTokenAddress).transferFrom(msg.sender, address(this), convertedValue);
        if(success){
            // if the lending token was successfully transferred then we withdraw USD from pool
            uint256 amountRecieved = ILendingPool(pool).withdraw(usdcCollateralAddress, convertedValue, msg.sender, address(this));
            
            if(amountRecieved ==  convertedValue){
                s_collateralDeposited[user][token] -= amount;
                // collateralToken(token).transferFrom(address(this), user, amount);
            }
            else{
                revert CollateralTokenWithdrawFailed(); 
            }
            revertIfHealthFactorIsBroken(user, token);
        }
    }

    function setLTokenAddress(address _newAddress)
    external
    onlyOwner
    {
        s_lTokenAddress = _newAddress;
    }

    function setUSDCTokenaddress(address _newAddress)
    external
    onlyOwner
    {

        usdcCollateralAddress = _newAddress;
    }

    ///////////////////////////////////////
    /// Private and Internal Functions ///
    //////////////////////////////////////

    function depositCollateral(address _pool, address _tokenToDeposit, address _tokenToLend, uint256 _amountCollateralToDeposit, uint256 amountUSDTtoDeposit, address _user)
    internal
    {
        bool success = collateralToken(_tokenToDeposit).transferFrom(msg.sender, address(this), _amountCollateralToDeposit);
        s_collateralDeposited[_user][_tokenToDeposit] += _amountCollateralToDeposit;
        if(!success){
            revert CollateralDepositionFailed();
        }
        bool _success = collateralToken(_tokenToLend).approve(_pool, amountUSDTtoDeposit);
        ILendingPool(_pool).deposit(_tokenToLend, amountUSDTtoDeposit, _user, 0);
        emit CollateralDeposited(_tokenToDeposit, _user);
    }

    function calculateRWAAmountfromUSD(uint256 amountInUsd, address tokenAddress)
    private
    returns(uint256 finalValue)
    {
        uint256 collateralUSDValue = getUSDValue(tokenAddress);
        uint256 finalCollateralValue = convertToSameUnit(tokenAddress, collateralUSDValue); 
        if(amountInUsd > finalCollateralValue){
            finalValue = amountInUsd / collateralUSDValue;
        } else{
            finalValue = amountInUsd;
        }
    }

    function calculateUSDFromRWA(
    uint256 amountCollateral, 
    address tokenToDeposit, 
    address tokenToLend)
    private
    returns(uint256)
    {
        uint256 collateralUSDValue = getUSDValue(tokenToDeposit);
        uint256 _finalValue = amountCollateral * (collateralUSDValue / PRECISION);
        uint256 finalValue = convertToTokenDecimal(tokenToDeposit, tokenToLend, _finalValue);
        return finalValue;
    }


    //////////////////////////////////////////////////
    /// Private & Internal View & Pure functions ///
    /////////////////////////////////////////////////

    function getUSDValue(address _token)
    private
    returns(uint256)
    {
        string memory tokenName = collateralToken(_token).symbol();
        string memory key = string.concat(tokenName, "/USD");
        (uint128 price, )= IDIAOracleV2(oracleAddress).getValue(key);

        return (uint256(price) * USD_PRECISION);
    }


    function getCollateralValueOfUser(address _token, address _user)
    private 
    returns(uint256 borrowAmount, uint256 userCollateralValue)
    {
        borrowAmount = s_BorrowAmount[_user][_token];
        userCollateralValue = s_collateralDeposited[_user][_token];
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
    returns(uint256)
    {
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

    function convertToSameUnit(address token, uint256 amount) 
    private 
    view 
    returns (uint256) 
    {

    uint8 tokenDecimals = allowedCollateralTokens[token];
    require(tokenDecimals <= 18, "Token decimals should be less than or equal to 18");
    
    // Calculate the conversion factor
    uint256 conversionFactor = 10**(18 - uint256(tokenDecimals));
    
    // Convert the amount to 18 decimals
    return amount * conversionFactor;

    }

    /* 
    @notice: This function is used to take in a token address, and an amount, and it converts the amount 
            back into the specified decimals, as it was in the collateral Contract
    */
    function convertToTokenDecimal(address _collateralAddress, address tokenToLend, uint256 _amountToBeConverted)
        private 
        view
        returns(uint256)
        {

            uint8 collateralTokenDecimals = allowedCollateralTokens[_collateralAddress];
            uint8 lendingTokenDecimals = allowedDepositTokens[tokenToLend];
            require(lendingTokenDecimals <= 18, "Token decimals should be less than or equal to 18");
            if (lendingTokenDecimals < 18){
            // Calculate the conversion factor
            uint256 conversionFactor = (18 - uint256(lendingTokenDecimals));

            uint256 finalVal = _amountToBeConverted/(10 ** uint256(collateralTokenDecimals)) * (10 ** uint256(lendingTokenDecimals));
        
            // Convert the amount to desired decimals
            return finalVal;
            }
            else if (lendingTokenDecimals == 18){
                return _amountToBeConverted;
            }
        }

        ////////////////////////////////////////////
        /// External and Public view functions ///
        ///////////////////////////////////////////

        function userDeposited(address _user, address _collateralToken)
        external
        view
        returns(uint256){
            return s_collateralDeposited[_user][_collateralToken];
        }

        function userBorrowed(address _user, address _collateralToken)
        external
        view
        returns(uint256){
            return s_BorrowAmount[_user][_collateralToken];
        }


}