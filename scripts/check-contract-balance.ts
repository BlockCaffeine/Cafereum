import hre from 'hardhat';
import 'dotenv/config';
import { contract } from './fixtures';
const ethers = hre.ethers;

async function main() {
  // Log contract balance
  const contractBalance = await contract.getBalance();
  console.log('Contract balance:', ethers.formatEther(contractBalance), 'UMETH');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
