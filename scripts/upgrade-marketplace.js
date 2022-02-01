const { ethers, upgrades } = require("hardhat");

async function main() {
  const proxyAddress = "0x4049c83db0Af762A142ebA4b3F0CD511825af6dB";
  const marketplace = await ethers.getContractFactory("OVRMarketplace");

  const upgraded = await upgrades.upgradeProxy(proxyAddress, marketplace);

  console.log("Proxy Upgraded: ", upgraded.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
