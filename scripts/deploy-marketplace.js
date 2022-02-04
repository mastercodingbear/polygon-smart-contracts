const { ethers, upgrades } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // https://github.com/maticnetwork/static/blob/master/network/mainnet/v1/index.json#L104
  const marketplace = await ethers.getContractFactory("OVRMarketplace");
  const OVRToken = "0xc9a4faafa5ec137c97947df0335e8784440f90b5";
  const OVRLand = "0x771468b89d8218d7f9b329DFbf4492320Ce28b8d";
  const OVRLandContainer = "0x1a5006044D89e73919239e7dc3455cF5512CBC27";
  const feeReceiver = "TODOOOOO";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const OVRMarketplace = await upgrades.deployProxy(
    marketplace,
    [OVRToken, OVRLand, OVRLandContainer, 500, feeReceiver],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  await OVRMarketplace.deployed();
  console.log("Proxy deployed to: ", OVRMarketplace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
