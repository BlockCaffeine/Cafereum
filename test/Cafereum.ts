import { loadFixture, time } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';

// Updated test suite for new Cafereum contract

describe('Cafereum', function () {
  async function deployCafereumFixture() {
    const SINGLE_COFFEE_PRICE = 1_000_000_000n; // 1 GWEI
    const DOUBLE_COFFEE_PRICE = 2_000_000_000n;
    const SINGLE_ESPRESSO_PRICE = 1_500_000_000n;
    const DOUBLE_ESPRESSO_PRICE = 2_500_000_000n;

    const [owner, otherAccount] = await hre.ethers.getSigners();

    const Cafereum = await hre.ethers.getContractFactory('Cafereum');
    const cafereum = await Cafereum.deploy(
      SINGLE_COFFEE_PRICE,
      DOUBLE_COFFEE_PRICE,
      SINGLE_ESPRESSO_PRICE,
      DOUBLE_ESPRESSO_PRICE
    );

    return {
      cafereum,
      owner,
      otherAccount,
      SINGLE_COFFEE_PRICE,
      DOUBLE_COFFEE_PRICE,
      SINGLE_ESPRESSO_PRICE,
      DOUBLE_ESPRESSO_PRICE,
    };
  }

  describe('Deployment', function () {
    it('Should set the right owner', async function () {
      const { cafereum, owner } = await loadFixture(deployCafereumFixture);
      expect(await cafereum.owner()).to.equal(owner.address);
    });

    it('Should set the right product prices', async function () {
      const { cafereum, SINGLE_COFFEE_PRICE, DOUBLE_COFFEE_PRICE, SINGLE_ESPRESSO_PRICE, DOUBLE_ESPRESSO_PRICE } = await loadFixture(deployCafereumFixture);
      expect(await cafereum.getProductPrice('SingleCoffee')).to.equal(SINGLE_COFFEE_PRICE);
      expect(await cafereum.getProductPrice('DoubleCoffee')).to.equal(DOUBLE_COFFEE_PRICE);
      expect(await cafereum.getProductPrice('SingleEspresso')).to.equal(SINGLE_ESPRESSO_PRICE);
      expect(await cafereum.getProductPrice('DoubleEspresso')).to.equal(DOUBLE_ESPRESSO_PRICE);
    });

    it('Should fail if SingleCoffee price is zero', async function () {
      const { DOUBLE_COFFEE_PRICE, SINGLE_ESPRESSO_PRICE, DOUBLE_ESPRESSO_PRICE } = await loadFixture(deployCafereumFixture);
      const Cafereum = await hre.ethers.getContractFactory('Cafereum');
      await expect(Cafereum.deploy(
        0,
        DOUBLE_COFFEE_PRICE,
        SINGLE_ESPRESSO_PRICE,
        DOUBLE_ESPRESSO_PRICE
      )).to.be.revertedWith('SingleCoffee price should be greater than zero');
    });

    it('Should fail if DoubleCoffee price is zero', async function () {
      const { SINGLE_COFFEE_PRICE, SINGLE_ESPRESSO_PRICE, DOUBLE_ESPRESSO_PRICE } = await loadFixture(deployCafereumFixture);
      const Cafereum = await hre.ethers.getContractFactory('Cafereum');
      await expect(Cafereum.deploy(
        SINGLE_COFFEE_PRICE,
        0,
        SINGLE_ESPRESSO_PRICE,
        DOUBLE_ESPRESSO_PRICE
      )).to.be.revertedWith('DoubleCoffee price should be greater than zero');
    });

    it('Should fail if SingleEspresso price is zero', async function () {
      const { SINGLE_COFFEE_PRICE, DOUBLE_COFFEE_PRICE, DOUBLE_ESPRESSO_PRICE } = await loadFixture(deployCafereumFixture);
      const Cafereum = await hre.ethers.getContractFactory('Cafereum');
      await expect(Cafereum.deploy(
        SINGLE_COFFEE_PRICE,
        DOUBLE_COFFEE_PRICE,
        0,
        DOUBLE_ESPRESSO_PRICE
      )).to.be.revertedWith('SingleEspresso price should be greater than zero');
    });

    it('Should fail if DoubleEspresso price is zero', async function () {
      const { SINGLE_COFFEE_PRICE, DOUBLE_COFFEE_PRICE, SINGLE_ESPRESSO_PRICE } = await loadFixture(deployCafereumFixture);
      const Cafereum = await hre.ethers.getContractFactory('Cafereum');
      await expect(Cafereum.deploy(
        SINGLE_COFFEE_PRICE,
        DOUBLE_COFFEE_PRICE,
        SINGLE_ESPRESSO_PRICE,
        0
      )).to.be.revertedWith('DoubleEspresso price should be greater than zero');
    });

  });

  describe('Purchasing Products', function () {
    it('Should allow purchasing a product with the correct price', async function () {
      const { cafereum, otherAccount, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      const productType = 'SingleCoffee';
      const productStrength = 'Normal';
      const tx = await cafereum.connect(otherAccount).buyProduct(productType, productStrength, { value: SINGLE_COFFEE_PRICE });
      const receipt = await tx.wait();
      if (!receipt) throw new Error('Transaction receipt is null');
      const block = await hre.ethers.provider.getBlock(receipt.blockNumber);
      const events = await cafereum.queryFilter(cafereum.filters.ProductPurchased());
      const event = events.find(e => e.transactionHash === tx.hash);
      expect(event?.args?.[0]).to.equal(productType);
      expect(event?.args?.[1]).to.equal(productStrength);
    });

    it('Should fail if the product price is incorrect', async function () {
      const { cafereum, otherAccount } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(otherAccount).buyProduct('SingleCoffee', 'Normal', { value: 123n })
      ).to.be.revertedWith('Incorrect amount sent');
    });

    it('Should fail if the product type is invalid', async function () {
      const { cafereum, otherAccount, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(otherAccount).buyProduct('InvalidType', 'Normal', { value: SINGLE_COFFEE_PRICE })
      ).to.be.revertedWith('Invalid product type');
    });

    it('Should fail if the product strength is invalid', async function () {
      const { cafereum, otherAccount, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(otherAccount).buyProduct('SingleCoffee', 'SuperStrong', { value: SINGLE_COFFEE_PRICE })
      ).to.be.revertedWith('Invalid product strength');
    });
  });

  describe('Withdrawing Funds', function () {
    it('Should allow the owner to withdraw funds', async function () {
      const { cafereum, owner, otherAccount, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      // Buy a product to fund the contract
      await cafereum.connect(otherAccount).buyProduct('SingleCoffee', 'Normal', { value: SINGLE_COFFEE_PRICE });
      const initialOwnerBalance = await hre.ethers.provider.getBalance(owner.address);
      // Get contract balance before withdrawal
      const contractBalance = await cafereum.getBalance();
      const tx = await cafereum.connect(owner).withdraw();
      const receipt = await tx.wait();
      if (!receipt) throw new Error('Transaction receipt is null');
      // Use gasPrice or effectiveGasPrice depending on availability
      const gasUsed = receipt.gasUsed;
      // @ts-ignore
      const gasPrice = receipt.effectiveGasPrice || receipt.gasPrice || tx.gasPrice;
      const gasCost = gasUsed * gasPrice;
      const finalOwnerBalance = await hre.ethers.provider.getBalance(owner.address);
      // Owner's balance should increase by (contractBalance - gasCost) (allowing for rounding)
      expect(finalOwnerBalance).to.be.closeTo(initialOwnerBalance + contractBalance - gasCost, 1_000_000_000_000n); // 0.001 ETH tolerance
      expect(await cafereum.getBalance()).to.equal(0);
    });

    it('Should fail if a non-owner tries to withdraw funds', async function () {
      const { cafereum, otherAccount } = await loadFixture(deployCafereumFixture);
      await expect(cafereum.connect(otherAccount).withdraw()).to.be.revertedWith('You are not the owner');
    });
  });

  describe('Product Price Management', function () {
    it('Should allow the owner to change the price of a product', async function () {
      const { cafereum, owner, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      const newPrice = SINGLE_COFFEE_PRICE + 1_000_000_000n;
      await cafereum.connect(owner).setProductPrice('SingleCoffee', newPrice);
      expect(await cafereum.getProductPrice('SingleCoffee')).to.equal(newPrice);
    });

    it('Should fail if a non-owner tries to change the price', async function () {
      const { cafereum, otherAccount, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(otherAccount).setProductPrice('SingleCoffee', SINGLE_COFFEE_PRICE + 1_000_000_000n)
      ).to.be.revertedWith('You are not the owner');
    });

    it('Should fail if setting price to zero', async function () {
      const { cafereum, owner } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(owner).setProductPrice('SingleCoffee', 0)
      ).to.be.revertedWith('Price must be greater than zero');
    });

    it('Should fail if setting price for an invalid product type', async function () {
      const { cafereum, owner } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(owner).setProductPrice('InvalidType', 1_000_000_000n)
      ).to.be.revertedWith('Invalid product type');
    });
  });

  describe('Product Price Retrieval', function () {
    it('Should return the correct price for SingleCoffee', async function () {
      const { cafereum, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      expect(await cafereum.getProductPrice('SingleCoffee')).to.equal(SINGLE_COFFEE_PRICE);
    });
    it('Should return the correct price for DoubleCoffee', async function () {
      const { cafereum, DOUBLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      expect(await cafereum.getProductPrice('DoubleCoffee')).to.equal(DOUBLE_COFFEE_PRICE);
    });
    it('Should return the correct price for SingleEspresso', async function () {
      const { cafereum, SINGLE_ESPRESSO_PRICE } = await loadFixture(deployCafereumFixture);
      expect(await cafereum.getProductPrice('SingleEspresso')).to.equal(SINGLE_ESPRESSO_PRICE);
    });
    it('Should return the correct price for DoubleEspresso', async function () {
      const { cafereum, DOUBLE_ESPRESSO_PRICE } = await loadFixture(deployCafereumFixture);
      expect(await cafereum.getProductPrice('DoubleEspresso')).to.equal(DOUBLE_ESPRESSO_PRICE);
    });
    it('Should return 0 for an unknown product type', async function () {
      const { cafereum } = await loadFixture(deployCafereumFixture);
      expect(await cafereum.getProductPrice('UnknownProduct')).to.equal(0);
    });
  });

  describe('Helper Functions', function () {
    it('isValidProductType should return true for valid types', async function () {
      const { cafereum } = await loadFixture(deployCafereumFixture);
      // Call via a public wrapper using callStatic
      for (const type of ['SingleCoffee', 'DoubleCoffee', 'SingleEspresso', 'DoubleEspresso']) {
        // buyProduct will revert for invalid strength, but for valid type and valid strength, it will pass
        await expect(
          cafereum.buyProduct(type, 'Normal', { value: await cafereum.getProductPrice(type) })
        ).not.to.be.revertedWith('Invalid product type');
      }
    });
    it('isValidProductType should return false for invalid types', async function () {
      const { cafereum, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.buyProduct('NotAType', 'Normal', { value: SINGLE_COFFEE_PRICE })
      ).to.be.revertedWith('Invalid product type');
    });
    it('isValidProductStrength should return true for valid strengths', async function () {
      const { cafereum, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      for (const strength of ['Mild', 'Normal', 'Strong', 'Extra']) {
        await expect(
          cafereum.buyProduct('SingleCoffee', strength, { value: SINGLE_COFFEE_PRICE })
        ).not.to.be.revertedWith('Invalid product strength');
      }
    });
    it('isValidProductStrength should return false for invalid strengths', async function () {
      const { cafereum, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.buyProduct('SingleCoffee', 'NotAStrength', { value: SINGLE_COFFEE_PRICE })
      ).to.be.revertedWith('Invalid product strength');
    });
    it('isValidProductPrice should return true for price > 0 (tested via setProductPrice)', async function () {
      const { cafereum, owner } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(owner).setProductPrice('SingleCoffee', 1_000_000_000n)
      ).not.to.be.revertedWith('Price must be greater than zero');
    });
    it('isValidProductPrice should return false for price = 0 (tested via setProductPrice)', async function () {
      const { cafereum, owner } = await loadFixture(deployCafereumFixture);
      await expect(
        cafereum.connect(owner).setProductPrice('SingleCoffee', 0)
      ).to.be.revertedWith('Price must be greater than zero');
    });
    it('compareStrings should return true for equal strings and false for different strings (indirectly tested)', async function () {
      const { cafereum, SINGLE_COFFEE_PRICE } = await loadFixture(deployCafereumFixture);
      // Equal strings: valid type
      await expect(
        cafereum.buyProduct('SingleCoffee', 'Normal', { value: SINGLE_COFFEE_PRICE })
      ).not.to.be.revertedWith('Invalid product type');
      // Different strings: invalid type
      await expect(
        cafereum.buyProduct('singlecoffee', 'Normal', { value: SINGLE_COFFEE_PRICE })
      ).to.be.revertedWith('Invalid product type');
    });
  });
});
