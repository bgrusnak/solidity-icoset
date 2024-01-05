// import { MockContract, smock } from "@defi-wonderland/smock";
const { ethers, artifacts } = require("hardhat");
const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const E10000 = ethers.parseEther("10000");
describe("Airdrop", function () {
    async function fixture() {
        const [owner, other] = await ethers.getSigners();
        const token = await ethers.deployContract("MockERC20", [E10000], owner);
        const tokenAddress = await token.getAddress();
        const vesting = await ethers.deployContract(
            "MockVesting",
            [tokenAddress, tokenAddress],
            owner
        );
        const vestingAddress = await vesting.getAddress();
        const airdrop = await ethers.deployContract("MockAirdrop", [
            tokenAddress,
            vestingAddress,
            ethers.encodeBytes32String(""),
        ]);
        const airdropAddress = await airdrop.getAddress();
        await vesting.updateAirdrop(airdropAddress);
        return {
            owner,
            other,
            airdrop,
            airdropAddress,
            token,
            tokenAddress,
            vesting,
            vestingAddress,
        };
    }

    beforeEach(async function () {
        Object.assign(this, await loadFixture(fixture));
    });

   /*  it("Do not to distribute tokens after aidrop", async function () {
        expect(await this.airdrop.cancelAirDrop(this.owner));
        await expect(
            this.airdrop.redeem(this.owner, [], 0)
        ).to.be.reverted
        // dWithCustomError(this.airdrop, "CannotReturnFunds");
    }); */
});
