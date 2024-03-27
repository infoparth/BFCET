// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    address to
  ) external returns (uint256);
}

interface erc20{

    function _mintToken(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 token) external;

    function transferFrom(address from, address to, uint256 amount) external returns(bool);

    function balanceOf(address)external returns (uint256);

}

contract lendingProtocol {

  error NotEnoughDepositToBorrow();

    mapping (address => mapping(address => uint256)) public depositCollateral;
    mapping (address => mapping(address => uint256)) public borrowCollateral;

    address public depositToken;
    address public borrowToken;

    address depositedAddress;

    bool public isLendingOn ;

    uint256 public latestPrice;

    constructor(address _address) {

      depositedAddress = _address;

    }

     function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
  ) external
  {

    depositCollateral[onBehalfOf][asset]  += amount;
    bool success = erc20(asset).transferFrom(msg.sender, address(this), amount);
    erc20(depositToken)._mintToken(onBehalfOf, amount);
  }

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external{

    borrowCollateral[onBehalfOf][asset] += amount;
    uint256  depoAmount = depositCollateral[onBehalfOf][depositedAddress];

    if(depoAmount >= amount){
    erc20(asset)._mintToken(onBehalfOf, (amount / 2));
    erc20(borrowToken)._mintToken(onBehalfOf, amount);
    }
    else{

      revert NotEnoughDepositToBorrow();
    }

  }

  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256){ 

    borrowCollateral[onBehalfOf][asset] -= amount;
    bool success = erc20(asset).transferFrom(msg.sender, address(this), amount);
    erc20(borrowToken).burnFrom(onBehalfOf, amount);

    return amount;
  }

  function withdraw(
    address asset,
    uint256 amount,
    address from,
    address to
  ) external returns (uint256){

    latestPrice = depositCollateral[from][asset];
    uint256 userBalance = erc20(depositToken).balanceOf(msg.sender);
    require(userBalance >= amount, "You can't withdraw");
    erc20(depositToken).burnFrom(msg.sender, amount);
    // bool success = erc20(asset).transferFrom(address(this), to, amount);
    return amount;


  }
  function setUserUseReserveAsCollateral(address asset, bool vari)
    external 
    returns(uint256){
      uint256  depoAmount = depositCollateral[msg.sender][asset];
      isLendingOn = vari;
      return depoAmount;
    }

  function setDepositToken(address _tokenAddress)
  public {
    depositToken = _tokenAddress;
  }

  function setBorrowToken(address _tokenAddress)
  public {
    borrowToken = _tokenAddress;
  }

  function checkDeposit(address _user, address _collateral)
  public 
  view
  returns(uint256)
  {

    return depositCollateral[_user][_collateral];

  }

  function checkBorrow(address _user, address _collateral)
  public 
  view
  returns(uint256)
  {

    return borrowCollateral[_user][_collateral];

  }



}