import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
// import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("draft", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  async function deployDraftFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Borrower = await ethers.getContractFactory("borrowToken");
    const borrower = await Borrower.deploy();

    const borrowAddress = await borrower.getAddress();

    // console.log("The Borrower Adress is: " + borrowAddress);

    const Lender = await ethers.getContractFactory("lendingToken");
    const lender = await Lender.deploy();

    const lendingAddress = await lender.getAddress();

    // console.log("The lending Address is: " + lendingAddress);

    const Oracle = await ethers.getContractFactory("testOracle");
    const oracle = await Oracle.deploy();

    const oracleAddress = await oracle.getAddress();

    // console.log("The Oracle Address is: " + oracleAddress);

    const CollateralLnB = await ethers.getContractFactory("collateralLnB");
    const collateralLnB = await CollateralLnB.deploy();

    const collateralLnBAddress = await collateralLnB.getAddress();

    // console.log("The CollateralLnB address is: " + collateralLnBAddress);s

    const Pool = await ethers.getContractFactory("lendingProtocol");
    const pool = await Pool.deploy(collateralLnBAddress);

    const poolAddress = await pool.getAddress();

    // console.log("The Pool address is " + poolAddress);

    await pool.setDepositToken(lendingAddress);
    await pool.setBorrowToken(borrowAddress);

    const Collateral = await ethers.getContractFactory("collateral");
    const collateral = await Collateral.deploy();

    const collateralAddress = await collateral.getAddress();

    // console.log("The Collateral address is: " + collateralAddress);

    const AssetBorrow = await ethers.getContractFactory("assetBorrow");
    const assetBorrow = await AssetBorrow.deploy();

    const assetBorrowAddress = await assetBorrow.getAddress();

    // console.log("The CollateralLnB address is: " + assetBorrowAddress);

    const Draft = await ethers.getContractFactory("draft");
    const draft = await Draft.deploy(
      owner,
      oracleAddress,
      lendingAddress,
      collateralLnB,
      collateralAddress
    );

    const draftAddress = await draft.getAddress();

    await draft.addDepositToken(lendingAddress);

    // console.log("The Draft address is: " + draftAddress);

    console.log(
      "----------------------------------------------------------------"
    );

    const lockedAmount = ethers.parseEther("1");

    await collateral._mintToken(owner, lockedAmount);

    await collateral._mintToken(owner, lockedAmount);

    await collateralLnB._mintToken(draftAddress, lockedAmount);

    await collateral.approve(draftAddress, lockedAmount, { from: owner });

    return {
      borrower,
      lender,
      oracle,
      pool,
      collateral,
      collateralLnB,
      draft,
      owner,
      borrowAddress,
      lendingAddress,
      oracleAddress,
      poolAddress,
      collateralAddress,
      collateralLnBAddress,
      assetBorrowAddress,
      draftAddress,
    };
  }

  describe("Deployment", function () {
    it("Should Mint some Collateral Token and Deposit", async function () {
      console.log(
        "---------------------------------------------------------------"
      );
      // const lockedAmount = ethers.parseEther("1");
      const lockedAmount = 100000000;

      const {
        lender,
        pool,
        collateral,
        draft,
        owner,
        oracleAddress,
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        draftAddress,
      } = await loadFixture(deployDraftFixture);

      await draft.depositCollateralAndLend(
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        owner,
        lockedAmount
      );

      expect(await draft.userDeposited(owner, collateralAddress)).to.equal(
        lockedAmount
      );
    });

    it("Should have the same number of ILengding tokens", async function () {
      const lockedAmount = 1000000000000;
      const amount = 10000000000;
      const {
        lender,
        collateral,
        draft,
        owner,
        oracle,
        pool,
        oracleAddress,
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        lendingAddress,
        draftAddress,
      } = await loadFixture(deployDraftFixture);

      await draft.depositCollateralAndLend(
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        owner,
        amount
      );

      const ownAdd = owner.address;

      const val = await lender.balanceOf(ownAdd);

      expect(val).to.equal(lockedAmount);
    });

    it("Should be able to withdraw collateral ", async function () {
      const lockedAmount = 10000000000;
      const amount = 2000000000;
      const approvalAmount = 200000000000;
      const {
        lender,
        collateral,
        collateralLnB,
        draft,
        owner,
        oracleAddress,
        pool,
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        lendingAddress,
        draftAddress,
      } = await loadFixture(deployDraftFixture);

      await draft.depositCollateralAndLend(
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        owner,
        lockedAmount
      );

      const ownAdd = owner.address;

      await lender.approve(draftAddress, approvalAmount, { from: owner });

      await draft.withdrawCollateral(
        poolAddress,
        collateralAddress,
        ownAdd,
        amount
      );

      expect(await draft.userDeposited(owner, collateralAddress)).to.equal(
        lockedAmount - amount
      );
    });

    it("Should pass the deposit and borrow in the draft Contract", async function () {
      // const lockedAmount = ethers.parseEther("1");
      const lockedAmount = 10000000000;
      const borrowAmount = 2000000000;

      const {
        borrower,
        lender,
        pool,
        collateral,
        collateralLnBAddress,
        draft,
        owner,
        oracleAddress,
        poolAddress,
        collateralAddress,
        assetBorrowAddress,
        draftAddress,
      } = await loadFixture(deployDraftFixture);

      await draft.depositCollateralAndBorrowToken(
        poolAddress,
        collateralAddress,
        assetBorrowAddress,
        owner,
        lockedAmount,
        borrowAmount,
        1
      );

      expect(await draft.userBorrowed(owner, collateralAddress)).to.equal(
        borrowAmount
      );
    });

    it("Should borrow some token and have same number of borrow tokens", async function () {
      // const lockedAmount = ethers.parseEther("1");
      const lockedAmount = 10000000000;
      const borrowAmount = 2000000000;

      const {
        borrower,
        lender,
        pool,
        collateral,
        draft,
        owner,
        oracleAddress,
        poolAddress,
        collateralAddress,
        assetBorrowAddress,
        draftAddress,
      } = await loadFixture(deployDraftFixture);

      await draft.depositCollateralAndBorrowToken(
        poolAddress,
        collateralAddress,
        assetBorrowAddress,
        owner,
        lockedAmount,
        borrowAmount,
        1
      );

      expect(await borrower.balanceOf(owner)).to.equal(borrowAmount);
    });

    it("Should allow repayment of Borrowed Tokens", async function () {
      // const lockedAmount = ethers.parseEther("1");
      const lockedAmount = 10000000000;

      const borrowAmount = 8000000000;

      const repayAmount = 1000000000;

      const {
        borrower,
        lender,
        pool,
        collateral,
        collateralLnB,
        draft,
        owner,
        oracleAddress,
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        draftAddress,
      } = await loadFixture(deployDraftFixture);

      await draft.depositCollateralAndBorrowToken(
        poolAddress,
        collateralAddress,
        collateralLnBAddress,
        owner,
        lockedAmount,
        borrowAmount,
        1
      );

      await collateralLnB._mintToken(owner, repayAmount);
      await collateralLnB.approve(draft, repayAmount, { from: owner });

      await draft.repayDebt(
        poolAddress,
        collateralLnBAddress,
        repayAmount,
        1,
        owner,
        { from: owner }
      );

      expect(await borrower.balanceOf(owner)).to.equal(
        borrowAmount - repayAmount
      );
    });
  });
});
