import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'dotenv/config';

// const walletPrivateKey = process.env.WALLET_PRIVATE_KEY ?? "";
const walletPrivateKey = process.env.WALLET_PRIVATE_KEY_LOCALHOST ?? "0x".padEnd(66, "0");

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    uniMaBlockchain: {
      url: "http://134.155.52.185:32779",
      chainId: 585858,
      accounts: [
        walletPrivateKey
      ],
    }
  }
};

export default config;

