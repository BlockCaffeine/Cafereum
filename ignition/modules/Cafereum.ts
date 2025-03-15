// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DEFAULT_COFFEE_PRICE = 1_000_000_000n; // 1 GWEI

const CafereumModule = buildModule("CafereumModule", (m) => {
  const coffeePrice = m.getParameter("coffeePrice", DEFAULT_COFFEE_PRICE);

  const cafereum = m.contract("Cafereum", [coffeePrice]);

  return { cafereum };
});

export default CafereumModule;
