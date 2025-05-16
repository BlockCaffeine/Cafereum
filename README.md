# Cafereum
Ethereum Smart Contract for the payment system.

## Prerequisites
- Ethereum wallet (MetaMask)
- Node.js (lts)
- NPM

## Environment Variables
- Create a `.env` file in the root directory and add the following variables:
```bash
WALLET_PRIVATE_KEY="your_private_key_from_metamask"
WALLET_PRIVATE_KEY_LOCALHOST="one_of_the_private_keys_when_running_npx_hardhat_node"

SMART_CONTRACT_ADDRESS="smart_contract_address"
SMART_CONTRACT_ADDRESS_LOCALHOST="smart_contract_address_localhost"
```

- The `SMART_CONTRACT_ADDRESS` of the first deployed contract on the (not) uniMa Blockchain is `0x5FbDB2315678afecb367f032d93F642f64180aa3`

## Development

1. Install dependencies
```bash
npm install
```
2. Compile the smart contract
```bash
npx hardhat compile
```
3. Run tests
```bash
npx hardhat test
```
4. Run tests with coverage
```bash
npx hardhat coverage
```
5. Deploy the smart contract
- (Un)comment the right environment variables in the `./hardhat.config.cts` file
- Run the deployment script
```bash
npx hardhat ignition deploy ./ignition/modules/Cafereum.ts --network uniMaBlockchain
```
or using the npm script
```bash
npm run deploy -- --network uniMaBlockchain
```

## Scripts

1. Set the right environment variables in the `.env` file
2. (Un)comment the right environment variables in the `./scripts/fixtures.ts` file
3. Run the scripts
```bash
npx hardhat run ./scripts/buy-product.ts --network uniMaBlockchain
npx hardhat run ./scripts/check-contract-balance.ts --network uniMaBlockchain
npx hardhat run ./scripts/withdraw-contract-balance.ts --network uniMaBlockchain
npx hardhat run ./scripts/set-product-price.ts --network uniMaBlockchain
```
or using the npm scripts (if defined)
```bash
npm run buy-product -- --network uniMaBlockchain
npm run check-contract-balance -- --network uniMaBlockchain
npm run withdraw-contract-balance -- --network uniMaBlockchain
npm run set-product-price -- --network uniMaBlockchain
```
