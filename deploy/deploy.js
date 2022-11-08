const { ethers, upgrades } = require("hardhat");

module.exports = async function ({ deployments, getNamedAccounts }) {
  const Box = await ethers.getContractFactory("Age")
  console.log("Deploying Age...")
  const box = await upgrades.deployProxy(Box,[42], { initializer: 'store'})

  console.log(box.address," age(proxy) address")
  console.log(await upgrades.erc1967.getImplementationAddress(box.address)," getImplementationAddress")
  console.log(await upgrades.erc1967.getAdminAddress(box.address)," getAdminAddress")    
}

module.exports.tags = ['UUPS'] 
