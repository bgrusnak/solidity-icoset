const {
    HardhatEthersSigner,
} = require("@nomicfoundation/hardhat-ethers/signers");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { zeroAddress } = require("viem");

const ETHER_PRICE = 200000000;
const START_BONUS = 20;
const NEW_BONUS = 40;
const E1 = ethers.parseEther("1");
const E9 = ethers.parseEther("9");
const E10 = ethers.parseEther("10");
const E100 = ethers.parseEther("100");
const E120 = ethers.parseEther("120");
const E200 = ethers.parseEther("200");
const E240 = ethers.parseEther("240");
const E760 = ethers.parseEther("760");
const E1000 = ethers.parseEther("1000");
const E2000 = ethers.parseEther("2000");
const E2400 = ethers.parseEther("2400");
const E10000 = ethers.parseEther("10000");
describe("Purchase", function () {
    async function fixture() {
        const [owner, client, referral] = await ethers.getSigners();
        const token = await ethers.deployContract(
            "MockERC20",
            [E10000],
            owner
        );
        const tokenAddress = await token.getAddress();

        const mock = await ethers.deployContract(
            "MockERC20",
            [E10000],
            owner
        );
        const mockAddress = await mock.getAddress();
        await mock.transfer(client, E1000);
        const chainlink = await ethers.deployContract(
            "MockChainlink",
            [ETHER_PRICE, 6],
            owner
        );
        const chainlinkAddress = await chainlink.getAddress();
        const purchase = await ethers.deployContract(
            "MockPurchase",
            [tokenAddress, chainlinkAddress, 1, START_BONUS],
            owner
        );
        const purchaseAddress = await purchase.getAddress();
        await purchase.setRate(mockAddress, E1);
        const vesting = await ethers.deployContract(
          "MockVesting",
          [tokenAddress, tokenAddress],
          owner
      );
      const vestingAddress = await vesting.getAddress();
        return {
            owner,
            client,
            token,
            purchase,
            tokenAddress,
            purchaseAddress,
            chainlink,
            chainlinkAddress,
            mock,
            mockAddress,
            referral,
            vesting, 
            vestingAddress
        };
    }

    beforeEach(async function () {
        Object.assign(this, await loadFixture(fixture));
    });

    it("Vesting is 0x0 by default", async function () {
        expect(await this.purchase.vesting()).to.equal(zeroAddress);
    });

    it("Cannot purchase if the currency is not defined in contract", async function () {
        await expect(
            this.purchase
                .connect(this.client)
                .buy(this.tokenAddress, E200, zeroAddress)
        ).to.be.revertedWithCustomError(this.purchase, "ZeroAmount");
    });

    it("Purchase with tokens falling if the client haven't funds", async function () {
        await expect(
            this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E2000, zeroAddress)
        ).to.be.revertedWithCustomError(this.purchase, "UnsufficientBalance");
    });

    it("Purchase with tokens falling if the purchase contract haven't funds", async function () {
        expect(await this.token.balanceOf(this.client)).to.equal(0);
        expect(
            await this.mock
                .connect(this.client)
                .approve(this.purchaseAddress, E200)
        );
        await expect(
            this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E200, zeroAddress)
        ).to.be.revertedWithCustomError(
            this.purchase,
            "UnsufficientPurchaseBalance"
        );
    });

    it("Purchase with tokens falling if the original token is not approved to transfer", async function () {
        await this.token.transfer(this.purchaseAddress, E200);
        await expect(
            this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E100, zeroAddress)
        ).to.be.revertedWithCustomError(
            this.mock,
            "ERC20InsufficientAllowance"
        );
    });

    it("Purchase with tokens with empty vesting is processed with bonus", async function () {
      expect(await this.token.balanceOf(this.client.address)).to.equal(0)
      expect(await this.token.transfer(this.purchaseAddress, E200));
        expect(
            await this.mock
                .connect(this.client)
                .approve(this.purchaseAddress, E100)
        );
        expect(
            await this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E100, zeroAddress)
        ).to.be.exist;
        expect(await this.token.balanceOf(this.client)).to.equal(E120)
    });
 

    it("Purchase with ether falling if the purchase contract haven't funds", async function () {
        expect(await this.token.balanceOf(this.client.address)).to.equal(0);
        await expect(
            this.purchase
                .connect(this.client)
                .deposit(zeroAddress, { value: ethers.parseEther("100") })
        ).to.be.revertedWithCustomError(
            this.purchase,
            "UnsufficientPurchaseBalance"
        );
    });
 

    it("Purchase with ether with empty vesting is processed with bonus", async function () {
      await this.token.transfer(this.purchaseAddress, E1000);
      expect(await ethers.provider.getBalance(this.purchaseAddress)).to.equal(0);
      expect(await this.token.balanceOf(this.client.address)).to.equal(0);
      expect( await this.purchase
          .connect(this.client)
          .deposit(zeroAddress, { value: E1 }));
        expect(await this.token.balanceOf(this.client.address)).to.equal(E240);
        expect(await ethers.provider.getBalance(this.purchaseAddress)).to.equal(E1);
    });


    it("Purchase is failed if the referral is itself", async function () {
      await expect( this.purchase
          .connect(this.client)
          .deposit(this.client.address, { value: ethers.parseEther("1") })).to.be.revertedWithCustomError(
            this.purchase,
            "BadReferrer"
        ); 
    });

    it("Purchase with empty buyer cannot be passed", async function () {
      expect(await this.token.balanceOf(this.client.address)).to.equal(0)
      expect(await this.token.transfer(this.purchaseAddress, E200));
        expect(
            await this.mock
                .connect(this.client)
                .approve(this.purchaseAddress, E100)
        );
        await expect(
          this.purchase
              .connect(this.client)
               ["buy(address,address,uint256,address)"](zeroAddress, this.mockAddress, E200, zeroAddress)
      ).to.be.revertedWithCustomError(
          this.purchase,
          "NoBuyerProvided"
      );
        
    });


    it("Purchase with tokens with empty vesting and referral in tokens is processed", async function () {
      expect(await this.token.balanceOf(this.client.address)).to.equal(0)
      expect(await this.token.balanceOf(this.referral.address)).to.equal(0)
      expect(await this.purchase.setTokenPercent(10))
      expect(await this.token.transfer(this.purchaseAddress, E200));
        expect(
            await this.mock
                .connect(this.client)
                .approve(this.purchaseAddress, E100)
        );
        expect(
            await this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E100, this.referral.address)
        ).to.be.exist;
        expect(await this.token.balanceOf(this.client.address)).to.equal(E120)
        expect(await this.token.balanceOf(this.referral.address)).to.equal(E10)
    });

    it("Purchase with tokens with empty vesting and referral in original coins is processed", async function () {
      expect(await this.token.balanceOf(this.client.address)).to.equal(0)
      expect(await this.mock.balanceOf(this.referral.address)).to.equal(0)
      expect(await this.purchase.setCashPercent(10))
      expect(await this.token.transfer(this.purchaseAddress, E200));
        expect(
            await this.mock
                .connect(this.client)
                .approve(this.purchaseAddress, E100)
        );
        expect(
            await this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E100, this.referral.address)
        ).to.be.exist;
        expect(await this.token.balanceOf(this.client.address)).to.equal(E120)
        expect(await this.mock.balanceOf(this.referral.address)).to.equal(E10)
    });
 
 
    it("Purchase with ether with empty vesting and referral in original coins is processed ", async function () {
      await this.token.transfer(this.purchaseAddress, E10000);
      expect(await ethers.provider.getBalance(this.purchaseAddress)).to.equal(0);
      const old = await ethers.provider.getBalance(this.referral.address);
      expect(await this.purchase.setCashPercent(10))
      expect(await this.token.balanceOf(this.client.address)).to.equal(0);
      expect( await this.purchase
          .connect(this.client)
          .deposit(this.referral.address, { value: E10 }));
        expect(await this.token.balanceOf(this.client.address)).to.equal(E2400);
        expect(await ethers.provider.getBalance(this.purchaseAddress)).to.equal(E9);
        expect(await ethers.provider.getBalance(this.referral.address)).to.equal(E1+old);
    });

    it("Purchase with tokens with vesting is processed", async function () {
      expect(await this.purchase.setVesting(this.vestingAddress))
      expect(await this.token.balanceOf(this.client.address)).to.equal(0)
      expect(await this.token.transfer(this.purchaseAddress, E200));
        expect(
            await this.mock
                .connect(this.client)
                .approve(this.purchaseAddress, E100)
        );
        expect(
            await this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E100, zeroAddress)
        ).to.be.exist;
        expect(await this.token.balanceOf(this.client.address)).to.equal(0)
        expect(await this.vesting.distributed(this.client.address)).to.equal(E120)
    });

    it("Purchase with tokens with vesting and referral is processed", async function () {
      expect(await this.purchase.setVesting(this.vestingAddress))
      expect(await this.token.balanceOf(this.client.address)).to.equal(0)
      expect(await this.purchase.setTokenPercent(10))
      expect(await this.token.transfer(this.purchaseAddress, E200));
        expect(
            await this.mock
                .connect(this.client)
                .approve(this.purchaseAddress, E100)
        );
        expect(
            await this.purchase
                .connect(this.client)
                .buy(this.mockAddress, E100, this.referral.address)
        ).to.be.exist;
        expect(await this.token.balanceOf(this.client.address)).to.equal(0)
        expect(await this.vesting.distributed(this.client.address)).to.equal(E120)
        expect(await this.vesting.distributed(this.referral.address)).to.equal(E10)
    });
 
 
});
