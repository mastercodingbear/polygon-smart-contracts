/* eslint-disable node/no-unsupported-features/node-builtins */
const { ethers } = require("hardhat");
const R = require("ramda");

const landsToMint = require("../scripts/lands-to-mint.js");
const contract = require("../artifacts/contracts/OVRLand.sol/OVRLand.json");

const contractAddress = "0x814A38b39507dFECC86a1A674644826B96f51414";

async function main() {
  let totalMinted = 0;
  const batchSize = 50;
  const OVRLand = await ethers.getContractAt(contract.abi, contractAddress);

  const splittedLandsToMint = R.splitEvery(batchSize, landsToMint);

  console.log("BatchSize: ", batchSize);

  console.time("BATCH_MINT");

  for (let i = 1; i <= R.length(splittedLandsToMint); i++) {
    const onlyAddresses = R.map((single) => single.to, splittedLandsToMint[i]);
    const onlyTokenIds = R.map(
      (single) => single.tokenId,
      splittedLandsToMint[i]
    );

    const arrayLenght = R.length(onlyAddresses);

    const tx = await OVRLand.batchMintLands(onlyAddresses, onlyTokenIds, {
      gasLimit: 8000000,
      gasPrice: 27000000000,
    }); // TODO CHECK GAS PRICE
    const receipt = await tx.wait();

    totalMinted += arrayLenght;

    console.timeLog("BATCH_MINT");
    console.log("Current Batch Block: ", i + 1);
    console.log("Total OVRLands Minted: ", totalMinted);
    console.log("Transaction Hash: ", receipt.transactionHash);
    console.log("___________________________________________________");
  }

  console.log("COMPLETED");
  console.timeEnd("BATCH_MINT");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
