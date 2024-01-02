// import { MockContract, smock } from "@defi-wonderland/smock";
const { ethers, artifacts } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe.only('Airdrop', function () {
  async function fixture() {
    const [owner, other] =  await ethers.getSigners(); 
    const contract = await ethers.deployContract('Airdrop', []);
    return { owner, other, contract };
  }

  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  it('Do not to distribute tokens after aidrop', async function () {
    expect(await this.contract.cancelAirDrop(this.owner))
    await expect(this.contract.redeem(this.owner, [] , 0))
      .to.be.revertedWithCustomError(this.contract, 'AirdropIsFinished') ;
  })
 
 
});
