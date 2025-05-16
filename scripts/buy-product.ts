import hre from 'hardhat';
import 'dotenv/config';
import { wallet, provider, contract } from './fixtures';
const ethers = hre.ethers;

const PRODUCT_TYPE = "SingleCoffee"; // valid: SingleCoffee, DoubleCoffee, SingleEspresso, DoubleEspresso
const PRODUCT_STRENGTH = "Normal"; // valid: Mild, Normal, Strong, Extra

async function main() {
  // Get wallet address and balance
  console.log('Wallet address:', wallet.address);

  const balanceBefore = await provider.getBalance(wallet.address);
  console.log('Wallet balance before transaction:', ethers.formatEther(balanceBefore), 'UMETH');

  // Get the current coffee price from the contract
  const coffeePrice = await contract.getProductPrice(PRODUCT_TYPE);
  console.log('Current coffee price:', ethers.formatEther(coffeePrice), 'UMETH');

  // Call the buyProduct function with valid arguments and correct price
  const tx = await contract.buyProduct(PRODUCT_TYPE, PRODUCT_STRENGTH, {
    value: coffeePrice,
  });

  console.log('Transaction hash:', tx.hash);
  await tx.wait();

  // Log amount of gas used for the transaction
  const receipt = await provider.getTransactionReceipt(tx.hash);
  if (!receipt) throw new Error('Transaction receipt not found');
  const gasFee = receipt.gasUsed * receipt.gasPrice;
  console.log('Gas fee:', ethers.formatEther(gasFee), 'UMETH');

  // Log wallet balance after transaction and the difference in comparison to the previous balance
  const balanceAfter = await provider.getBalance(wallet.address);
  console.log('Wallet balance after transaction:', ethers.formatEther(balanceAfter), 'UMETH');

  const balanceDifference = balanceBefore - balanceAfter;
  console.log('Balance difference:', ethers.formatEther(balanceDifference), 'UMETH');

  // Log contract balance
  const contractBalance = await contract.getBalance();
  console.log('Contract balance:', ethers.formatEther(contractBalance), 'UMETH');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
