// import { MockContract, smock } from "@defi-wonderland/smock";
const { ethers, artifacts } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('Freezable', function () {
  async function fixture() {
    const [owner, other] =  await ethers.getSigners(); 
    const contract = await ethers.deployContract('MockFreezable', []);
    return { owner, other, contract };
  }

  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  it('prevents to call frozen function', async function () {
      await expect(this.contract.onlyFreezed(1))
      .to.be.revertedWithCustomError(this.contract, 'ExpectedFreeze') ;
  })

  it('prevents to call not frozen function', async function () {
    await this.contract.freeze(this.other);
    await expect(this.contract.connect(this.other).onlyMelted(1))
    .to.be.revertedWithCustomError(this.contract, 'EnforcedFreeze').withArgs(this.other) ;
  })

  it('succesfully call function if frozen to other one', async function () {
    await this.contract.freeze(this.other);
    expect(await this.contract.onlyMelted(1))
    .to.be.satisfies;
  })

  it('succesfully returns correct values', async function () {
    await this.contract.freeze(this.other);
    expect(await this.contract.freezed(this.other))
    .to.be.true;
    expect(await this.contract.freezed(this.owner))
    .to.be.false;
  })
 
});
