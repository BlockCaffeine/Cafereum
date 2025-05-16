import hre from 'hardhat';
import 'dotenv/config';
const ethers = hre.ethers;

// const walletPrivateKey = process.env.WALLET_PRIVATE_KEY;
const walletPrivateKey = process.env.WALLET_PRIVATE_KEY_LOCALHOST;

if (!walletPrivateKey) throw new Error('PRIVATE_KEY is not defined in the environment variables');

const contractAddress = process.env.SMART_CONTRACT_ADDRESS;

if (!contractAddress) throw new Error('SMART_CONTRACT_ADDRESS is not defined in the environment variables');

export { contractAddress };
export const abi = hre.artifacts.readArtifactSync('Cafereum').abi;
export const wallet = new ethers.Wallet(walletPrivateKey, ethers.provider);
export const contract = new ethers.Contract(contractAddress, abi, wallet);
export const provider = ethers.provider;
