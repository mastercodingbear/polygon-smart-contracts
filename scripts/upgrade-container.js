const { ethers, upgrades } = require("hardhat");

async function main() {
  const proxyAddress = "";
  const container = await ethers.getContractFactory("OVRLandContainer");

  const upgraded = await upgrades.upgradeProxy(proxyAddress, container);

  console.log("Proxy Upgraded: ", upgraded.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
