const Utils = artifacts.require("Utils")
const PrivateKeys = artifacts.require("PrivateKeys")
const Archaeologists = artifacts.require("Archaeologists")
const Sarcophaguses = artifacts.require("Sarcophaguses")

module.exports = async function (deployer) {
  await deployer.deploy(Utils)

  deployer.link(Utils, Archaeologists)
  await deployer.deploy(Archaeologists)

  await deployer.deploy(PrivateKeys)

  deployer.link(Utils, Sarcophaguses)
  deployer.link(Archaeologists, Sarcophaguses)
  deployer.link(PrivateKeys, Sarcophaguses)
  await deployer.deploy(Sarcophaguses)
}
