import hre from 'hardhat';
import 'dotenv/config';
import { wallet, provider, contract, contractAddress, abi } from './fixtures';
const ethers = hre.ethers;

// Define buyer personas with different purchasing patterns
const buyerPersonas = [
  {
    name: "Alice - Coffee Enthusiast",
    purchases: [
      { product: "SingleCoffee", strength: "Strong", count: 8 },
      { product: "DoubleCoffee", strength: "Extra", count: 5 },
      { product: "SingleEspresso", strength: "Normal", count: 2 }
    ]
  },
  {
    name: "Bob - Espresso Lover", 
    purchases: [
      { product: "SingleEspresso", strength: "Strong", count: 4 },
      { product: "DoubleEspresso", strength: "Extra", count: 3 },
      { product: "SingleCoffee", strength: "Mild", count: 1 }
    ]
  },
  {
    name: "Charlie - Balanced Buyer",
    purchases: [
      { product: "SingleCoffee", strength: "Normal", count: 6 },
      { product: "SingleEspresso", strength: "Normal", count: 6 },
      { product: "DoubleCoffee", strength: "Strong", count: 3 },
      { product: "DoubleEspresso", strength: "Strong", count: 3 }
    ]
  }
];

async function createAndFundWallet(index: number): Promise<any> {
  // Create a new random wallet
  const newWallet = ethers.Wallet.createRandom().connect(provider);
  console.log(`\nCreated wallet ${index + 1}: ${newWallet.address}`);
  
  // Fund the new wallet with 0.25 UMETH from the main wallet
  const fundingAmount = ethers.parseEther("0.25"); // 0.25 UMETH
  const fundingTx = await wallet.sendTransaction({
    to: newWallet.address,
    value: fundingAmount
  });
  
  await fundingTx.wait();
  console.log(`Funded with 0.25 UMETH (tx: ${fundingTx.hash})`);
  
  // Create contract instance connected to the new wallet
  const walletContract = new ethers.Contract(contractAddress!, abi, newWallet);
  
  return { wallet: newWallet, contract: walletContract };
}

async function makePurchases(buyerWallet: any, buyerContract: any, persona: any) {
  console.log(`\n${persona.name} starting purchases...`);
  
  let totalSpent = 0n;
  let totalPurchases = 0;
  
  for (const purchase of persona.purchases) {
    const productPrice = await buyerContract.getProductPrice(purchase.product);
    console.log(`${purchase.product} (${purchase.strength}): ${ethers.formatEther(productPrice)} UMETH x${purchase.count}`);
    
    // Make multiple purchases of the same product
    for (let i = 0; i < purchase.count; i++) {
      try {
        const tx = await buyerContract.buyProduct(purchase.product, purchase.strength, {
          value: productPrice,
          gasLimit: 500000 // Set reasonable gas limit
        });
        
        await tx.wait();
        totalSpent += productPrice;
        totalPurchases++;
        
        // Add small delay to avoid overwhelming the network
        if (i < purchase.count - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      } catch (error: any) {
        console.error(`Failed purchase ${i + 1} of ${purchase.product}:`, error.message);
      }
    }
  }
  
  console.log(`Completed ${totalPurchases} purchases, spent ${ethers.formatEther(totalSpent)} UMETH`);
  return { totalSpent, totalPurchases };
}

async function main() {
  console.log("Starting Traffic Generation for Cafereum Contract");
  console.log("=".repeat(50));
  console.log(`Main wallet: ${wallet.address}`);
  console.log(`Contract: ${contractAddress}`);
  
  // Check initial balances
  const initialBalance = await provider.getBalance(wallet.address);
  console.log(`Initial main wallet balance: ${ethers.formatEther(initialBalance)} UMETH`);
  
  // Get current product prices
  console.log("\nCurrent Product Prices:");
  const [productNames, productPrices] = await contract.getProductNamesAndPrices();
  for (let i = 0; i < productNames.length; i++) {
    console.log(`${productNames[i]}: ${ethers.formatEther(productPrices[i])} UMETH`);
  }
  
  // Create and fund wallets
  console.log("\nCreating and funding buyer wallets...");
  const buyers = [];
  
  for (let i = 0; i < buyerPersonas.length; i++) {
    try {
      const buyer = await createAndFundWallet(i);
      buyers.push(buyer);
    } catch (error: any) {
      console.error(`Failed to create wallet ${i + 1}:`, error.message);
    }
  }
  
  console.log(`\nSuccessfully created ${buyers.length} buyer wallets`);
  
  // Execute purchases for each buyer
  console.log("\nExecuting purchase patterns...");
  
  for (let i = 0; i < buyers.length && i < buyerPersonas.length; i++) {
    try {
      await makePurchases(buyers[i].wallet, buyers[i].contract, buyerPersonas[i]);
    } catch (error: any) {
      console.error(`Error with buyer ${i + 1}:`, error.message);
    }
  }
  
  // Final balance check
  const finalBalance = await provider.getBalance(wallet.address);
  const balanceUsed = initialBalance - finalBalance;
  console.log(`\nMain wallet balance used: ${ethers.formatEther(balanceUsed)} UMETH`);
  console.log(`Main wallet balance remaining: ${ethers.formatEther(finalBalance)} UMETH`);
  
  console.log("\nTraffic generation complete!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
