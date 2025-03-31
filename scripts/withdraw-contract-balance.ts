import hre from 'hardhat';
import 'dotenv/config';
import { wallet, provider, contract } from './fixtures';
const ethers = hre.ethers;

async function main() {
  // Log wallet balance before withdrawal
  const walletBalanceBeforeTransaction = await provider.getBalance(wallet.address);
  console.log('Wallet balance before withdrawl:', ethers.formatEther(walletBalanceBeforeTransaction), 'UMETH');

  // Log contract balance before withdrawal
  const contractBalanceBeforeTransaction = await contract.getBalance();
  console.log('Contract balance before withdrawal:', ethers.formatEther(contractBalanceBeforeTransaction), 'UMETH');

  // Call the withdraw function
  const tx = await contract.withdraw();
  
  console.log('Transaction hash:', tx.hash);
  await tx.wait();

  // Log amount of gas used for the transaction
  const receipt = await provider.getTransactionReceipt(tx.hash);
  if (!receipt) throw new Error('Transaction receipt not found');
  const gasFee = receipt.gasUsed * receipt.gasPrice;
  console.log('Gas fee:', ethers.formatEther(gasFee), 'UMETH');

  // Log wallet balance after withdrawal
  const walletBalanceAfterTransaction = await provider.getBalance(wallet.address);
  console.log('Wallet balance after withdrawal:', ethers.formatEther(walletBalanceAfterTransaction), 'UMETH');

  // Log contract balance after withdrawal
  const contractBalanceAfterTransaction = await contract.getBalance();
  console.log('Contract balance after withdrawl:', ethers.formatEther(contractBalanceAfterTransaction), 'UMETH');

  // Log the difference in wallet balance
  const walletBalanceDifference = walletBalanceAfterTransaction - walletBalanceBeforeTransaction;
  console.log('Wallet balance difference:', ethers.formatEther(walletBalanceDifference), 'UMETH');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
