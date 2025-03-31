// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import hre  from 'hardhat';
import { ethers } from "ethers";

const DEFAULT_COFFEE_PRICE = hre.ethers.parseEther("0.01");

const CafereumModule = buildModule("CafereumModule", (m) => {
  const coffeePrice = m.getParameter("coffeePrice", DEFAULT_COFFEE_PRICE);

  const cafereum = m.contract("Cafereum", [coffeePrice]);

  return { cafereum };
});

export default CafereumModule;
