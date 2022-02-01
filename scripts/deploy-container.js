const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploying
  const token = await ethers.getContractFactory("OVRLandContainer");
  const OVRLandAddress = "0x771468b89d8218d7f9b329DFbf4492320Ce28b8d";
  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const instance = await upgrades.deployProxy(token, [OVRLandAddress], {
    initializer: "initialize",
    kind: "uups",
  });
  await instance.deployed();
  console.log("Proxy deployed to: ", instance.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
