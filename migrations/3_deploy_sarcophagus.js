const SarcoTokenMock = artifacts.require("SarcoTokenMock")
const Sarcophagus = artifacts.require("Sarcophagus")

module.exports = async function (deployer, network) {
  let sarcoTokenAddress
  if (["develop", "test"].includes(network)) {
    await deployer.deploy(SarcoTokenMock)
    const sarcoTokenMock = await SarcoTokenMock.deployed()
    sarcoTokenAddress = sarcoTokenMock.address
  } else if (["goerli", "goerli-fork"].includes(network)) {
    sarcoTokenAddress = "0x4633b43990b41B57b3678c6F3Ac35bA75C3D8436"
  } else if (["mainnet", "mainnet-fork"].includes(network)) {
    sarcoTokenAddress = "0x7697b462a7c4ff5f8b55bdbc2f4076c2af9cf51a"
  } else {
    console.error("Which network are we on?")
    process.exit(1)
  }

  deployer.deploy(Sarcophagus, sarcoTokenAddress)
}
