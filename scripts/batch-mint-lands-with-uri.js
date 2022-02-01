/* eslint-disable node/no-unsupported-features/node-builtins */
const { ethers } = require("hardhat");
const R = require("ramda");

const landsToMintJson = require("../scripts/edited_alpha_mint_lands.json");
const contract = require("../artifacts/contracts/OVRLand.sol/OVRLand.json");

const contractAddress = "0x624A4029dCc396B2d31a20eAFffd8fd118859aA0";

function main() {
  execution().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

const execution = async () => {
  let totalMinted = 0;
  const batchSize = 50;
  // console.log("landsToMintJson", landsToMintJson);
  // const landsToMint = JSON.parse("" + landsToMintJson + "");
  const OVRLand = await ethers.getContractAt(contract.abi, contractAddress);

  const splittedLandsToMint = R.splitEvery(batchSize, landsToMintJson);

  console.log("BatchSize: ", batchSize);

  console.time("BATCH_MINT_WITH_URI");

  for (let i = 0; i < R.length(splittedLandsToMint); i++) {
    const onlyAddresses = R.map((single) => single.to, splittedLandsToMint[i]);
    const onlyTokenIds = R.map(
      (single) => single.tokenId,
      splittedLandsToMint[i]
    );
    console.debug("Last TokenID", R.last(onlyTokenIds));
    const onlyUris = R.map((single) => single.uri, splittedLandsToMint[i]);

    const arrayLenght = R.length(onlyAddresses);

    const tx = await OVRLand.batchMintLandsWithUri(
      onlyAddresses,
      onlyTokenIds,
      onlyUris,
      {
        gasLimit: 12000000,
        gasPrice: 30000000000,
      }
    );
    const receipt = await tx.wait();

    totalMinted += arrayLenght;

    console.timeLog("BATCH_MINT_WITH_URI");
    console.log("Current Batch Block: ", i + 1);
    console.log("Total OVRLands Minted: ", totalMinted);
    console.log("Transaction Hash: ", receipt.transactionHash);
    console.log("___________________________________________________");
  }

  console.log("COMPLETED");
  console.timeEnd("BATCH_MINT_WITH_URI");
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main();
