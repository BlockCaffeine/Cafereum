import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'dotenv/config';

// const walletPrivateKey = process.env.WALLET_PRIVATE_KEY;
const walletPrivateKey = process.env.WALLET_PRIVATE_KEY_LOCALHOST;

if (!walletPrivateKey) throw new Error('WALLET_PRIVATE_KEY is not defined in the environment variables');

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    uniMa: {
      url: "https://fortuna.informatik.uni-mannheim.de:8506",
      chainId: 1337,
      accounts: [walletPrivateKey],
    }
  }
};

export default config;
