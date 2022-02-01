// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // https://github.com/maticnetwork/static/blob/master/network/mainnet/v1/index.json#L104
  const OVRLandContractMAINNET = "0x93C46aA4DdfD0413d95D0eF3c478982997cE9861";

  // https://github.com/maticnetwork/static/blob/master/network/testnet/mumbai/index.json#L105
  const OVRLandContractTESTNET = "0x624A4029dCc396B2d31a20eAFffd8fd118859aA0";

  // We get the contract to deploy
  const LightMint = await hre.ethers.getContractFactory("LightMint");
  const lightMint = await LightMint.deploy(OVRLandContractMAINNET);

  await lightMint.deployed();

  console.log("OVRLand deployed to:", lightMint.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
