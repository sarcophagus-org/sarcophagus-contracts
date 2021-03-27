const { deployProxy } = require("@openzeppelin/truffle-upgrades")
const SarcoTokenMock = artifacts.require("SarcoTokenMock")
const Sarcophagus = artifacts.require("Sarcophagus")
const Archaeologists = artifacts.require("Archaeologists")
const Sarcophaguses = artifacts.require("Sarcophaguses")

module.exports = async function (deployer, network) {
  let sarcoTokenAddress
  if (["develop", "test", "soliditycoverage"].includes(network)) {
    await deployer.deploy(SarcoTokenMock)
    const sarcoTokenMock = await SarcoTokenMock.deployed()
    sarcoTokenAddress = sarcoTokenMock.address
  } else if (["rinkeby", "rinkeby-fork"].includes(network)) {
    sarcoTokenAddress = "0x77Ec161f6C2F2ce4554695A07e071d3f0eF3aef5"
  } else if (["goerli", "goerli-fork"].includes(network)) {
    sarcoTokenAddress = "0x4633b43990b41B57b3678c6F3Ac35bA75C3D8436"
  } else if (["mainnet", "mainnet-fork"].includes(network)) {
    sarcoTokenAddress = "0x7697b462a7c4ff5f8b55bdbc2f4076c2af9cf51a"
  } else {
    console.error("Which network are we on?")
    console.error(network)
    process.exit(1)
  }

  deployer.link(Archaeologists, Sarcophagus)
  deployer.link(Sarcophaguses, Sarcophagus)
  await deployProxy(Sarcophagus, [sarcoTokenAddress], { deployer, unsafeAllowLinkedLibraries: true })
}
