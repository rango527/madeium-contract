const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const NFT = await hre.ethers.getContractFactory("NFT");
  // allowMintDate = 1650326400, 2022-04-19 00:00:00 GMT+0
  // publicMintDate = 1650412800, 2022-04-20 00:00:00 GMT+0
  const nft = await NFT.deploy("https://example.com/", "https://example.com/", "0xA6431D80240C3a3FeF54Dd2179b2BDC13fEec467", 100, 1650326400, 1650412800);

  await nft.deployed();

  console.log("NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
