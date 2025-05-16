import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'dotenv/config';

const walletPrivateKey = process.env.WALLET_PRIVATE_KEY ?? "";

const config: HardhatUserConfig = {
  solidity: '0.8.28',
  networks: {
    uniMaBlockchain: {
      url: 'https://fortuna.informatik.uni-mannheim.de:32779',
      chainId: 585858,
      accounts: [walletPrivateKey],
    },
  },
};

export default config;
