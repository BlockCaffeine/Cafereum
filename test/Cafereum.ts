import { loadFixture, time } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';

describe('Cafereum', function () {
  async function deployCafereumFixture() {
    const DEFAULT_COFFEE_PRICE = 1_000_000_000n; // 1 GWEI

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const Cafereum = await hre.ethers.getContractFactory('Cafereum');
    const cafereum = await Cafereum.deploy(DEFAULT_COFFEE_PRICE);

    return { cafereum, DEFAULT_COFFEE_PRICE, owner, otherAccount };
  }

  describe('Deployment', function () {
    it('Should set the right coffee price', async function () {
      const { cafereum, DEFAULT_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);

      expect(await cafereum.coffeePrice()).to.equal(DEFAULT_COFFEE_PRICE);
    });

    it('Should set the right owner', async function () {
      const { cafereum, owner } = await loadFixture(deployCafereumFixture);

      expect(await cafereum.owner()).to.equal(owner.address);
    });
  });

  describe('Purchasing Coffee', function () {
    it('Should allow purchasing coffee with the correct price', async function () {
      const { cafereum, otherAccount } = await loadFixture(deployCafereumFixture);

      const tx = (await cafereum.connect(otherAccount).buyCoffee({ value: 1_000_000_000n }));
      const txReceipt = await tx.wait();
      if (!txReceipt) throw new Error('Transaction receipt not found');

      const block = await hre.ethers.provider.getBlock(txReceipt.blockNumber);
      if (!block) throw new Error('Block not found');
  
      const coffeePurchasedEvent = (await cafereum.queryFilter(cafereum.filters.CoffeePurchased(), block.number))[0];

      expect(coffeePurchasedEvent.args?.[0]).to.equal(otherAccount.address);
      expect(coffeePurchasedEvent.args?.[1]).to.equal(1_000_000_000n);
      expect(coffeePurchasedEvent.args?.[2]).to.within(block.timestamp - 5, block.timestamp + 5);
    });

    it('Should fail if the coffee price is incorrect', async function () {
      const { cafereum, otherAccount } = await loadFixture(deployCafereumFixture);

      await expect(cafereum.connect(otherAccount).buyCoffee({ value: 500_000_000n })).to.be.revertedWith('Incorrect amount sent');
    });
  });

  describe('Withdrawing Funds', function () {
    it('Should allow the owner to withdraw funds', async function () {
      const { cafereum, owner } = await loadFixture(deployCafereumFixture);
      
      const initialOwnerBalance = await hre.ethers.provider.getBalance(owner.getAddress());
      const tx = await cafereum.connect(owner).withdraw();
      const finalOwnerBalance = await hre.ethers.provider.getBalance(owner.getAddress());

      expect(await cafereum.getBalance()).to.equal(0);
      const txGas = tx.gasPrice * tx.gasLimit
      expect(finalOwnerBalance).to.be.above(initialOwnerBalance - txGas);
    });

    it('Should fail if a non-owner tries to withdraw funds', async function () {
      const { cafereum, otherAccount } = await loadFixture(deployCafereumFixture);

      await expect(cafereum.connect(otherAccount).withdraw()).to.be.revertedWith('You are not the owner');
    });
  });
});
