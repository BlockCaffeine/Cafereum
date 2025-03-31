import hre from 'hardhat';
import 'dotenv/config';
import { wallet, provider, contract } from './fixtures';
const ethers = hre.ethers;

async function main() {
  // Get wallet address and balance
  console.log('Wallet address:', wallet.address);

  const balanceBefore = await provider.getBalance(wallet.address);
  console.log('Wallet balance before transaction:', ethers.formatEther(balanceBefore), 'UMETH');

  // Call the buyCoffee function
  const tx = await contract.buyCoffee({
    value: ethers.parseEther('0.01'),
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
