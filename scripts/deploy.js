
const {ethers} = require("hardhat");

async function main() {

  const network = await hre.network;

  const feePayer = "0xE94df9BA27346DDF715e715aB3e8A61FAD66a52D";

  const gatewayContract =

    network.config.chainId == 43113

      ? "0xcAa6223D0d41FB27d6FC81428779751317FC24cB"

      : "0xcAa6223D0d41FB27d6FC81428779751317FC24cB";

  const PingPong = await ethers.getContractFactory("PingPong");

  const pingpong = await PingPong.deploy(

    gatewayContract,

    feePayer

  );

  await pingpong.deployed();
  
  console.log("PingPong deployed to:", pingpong.address);
 
  await hre.run("verify:verify", {

    address: pingpong.address,

    constructorArguments: [gatewayContract,feePayer],

  });

}


main()

  .then(() => process.exit(0))

  .catch((error) => {

    console.error(error);

    process.exitCode = 1;

  });