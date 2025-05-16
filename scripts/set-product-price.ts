import hre from 'hardhat';
import 'dotenv/config';
import { wallet, contract } from './fixtures';
const ethers = hre.ethers;

const PRODUCT_TYPE = process.env.PRODUCT_TYPE || 'SingleCoffee'; // e.g. SingleCoffee, DoubleCoffee, SingleEspresso, DoubleEspresso
const NEW_PRICE_UMETH = process.env.NEW_PRICE_UMETH || '0.01'; // e.g. '0.01' for 0.01 UMETH

async function main() {
  // Log wallet address
  console.log('Wallet address:', wallet.address);

  // Get current price
  const oldPrice = await contract.getProductPrice(PRODUCT_TYPE);
  console.log(`Current price for ${PRODUCT_TYPE}:`, ethers.formatEther(oldPrice), 'UMETH');

  // Set new price
  const newPrice = ethers.parseEther(NEW_PRICE_UMETH);
  const tx = await contract.setProductPrice(PRODUCT_TYPE, newPrice);
  console.log('Transaction hash:', tx.hash);
  await tx.wait();

  // Get updated price
  const updatedPrice = await contract.getProductPrice(PRODUCT_TYPE);
  console.log(`Updated price for ${PRODUCT_TYPE}:`, ethers.formatEther(updatedPrice), 'UMETH');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
