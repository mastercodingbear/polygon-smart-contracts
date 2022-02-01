const { ethers, upgrades } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // https://github.com/maticnetwork/static/blob/master/network/mainnet/v1/index.json#L104
  const ChildChainManagerProxyMAINNET =
    "0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa";

  // https://github.com/maticnetwork/static/blob/master/network/testnet/mumbai/index.json#L105
  const ChildChainManagerProxyTESTNET =
    "0xb5505a6d998549090530911180f38aC5130101c6";

  // We get the contract to deploy
  const OVRLand = await hre.ethers.getContractFactory("OVRLand");
  const ovrland = await OVRLand.deploy(ChildChainManagerProxyTESTNET);

  await ovrland.deployed();

  console.log("OVRLand deployed to:", ovrland.address);

  const token = await ethers.getContractFactory("OVRLandContainer");
  const OVRLandAddress = ovrland.address;
  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const OVRContainer = await upgrades.deployProxy(token, [OVRLandAddress], {
    initializer: "initialize",
    kind: "uups",
  });
  await instance.deployed();
  console.log("Proxy deployed to: ", OVRContainer.address);

  const marketplace = await ethers.getContractFactory("OVRMarketplace");
  const OVRToken = "0xc9a4faafa5ec137c97947df0335e8784440f90b5";
  const OVRLandContainer = OVRContainer.address;
  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const OVRMarketplace = await upgrades.deployProxy(
    marketplace,
    [OVRToken, OVRLandAddress, OVRLandContainer, 500],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  await instance.deployed();
  console.log("Proxy deployed to: ", OVRMarketplace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
