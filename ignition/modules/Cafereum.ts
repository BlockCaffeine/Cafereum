// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import hre  from 'hardhat';

const DEFAULT_SINGLE_COFFEE_PRICE = hre.ethers.parseEther("0.01");
const DEFAULT_DOUBLE_COFFEE_PRICE = hre.ethers.parseEther("0.018");
const DEFAULT_SINGLE_ESPRESSO_PRICE = hre.ethers.parseEther("0.012");
const DEFAULT_DOUBLE_ESPRESSO_PRICE = hre.ethers.parseEther("0.02");

const CafereumModule = buildModule("CafereumModule", (m) => {
  const singleCoffeePrice = m.getParameter("singleCoffeePrice", DEFAULT_SINGLE_COFFEE_PRICE);
  const doubleCoffeePrice = m.getParameter("doubleCoffeePrice", DEFAULT_DOUBLE_COFFEE_PRICE);
  const singleEspressoPrice = m.getParameter("singleEspressoPrice", DEFAULT_SINGLE_ESPRESSO_PRICE);
  const doubleEspressoPrice = m.getParameter("doubleEspressoPrice", DEFAULT_DOUBLE_ESPRESSO_PRICE);

  const cafereum = m.contract("Cafereum", [singleCoffeePrice, doubleCoffeePrice, singleEspressoPrice, doubleEspressoPrice]);

  return { cafereum };
});

export default CafereumModule;
