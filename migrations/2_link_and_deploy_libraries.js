const Utils = artifacts.require("Utils")
const PrivateKeys = artifacts.require("PrivateKeys")
const Archaeologists = artifacts.require("Archaeologists")
const Sarcophaguses = artifacts.require("Sarcophaguses")

module.exports = function (deployer) {
  deployer.deploy(Utils)

  deployer.link(Utils, Archaeologists)
  deployer.deploy(Archaeologists)

  deployer.deploy(PrivateKeys)

  deployer.link(Utils, Sarcophaguses)
  deployer.link(Archaeologists, Sarcophaguses)
  deployer.link(PrivateKeys, Sarcophaguses)
  deployer.deploy(Sarcophaguses)
}
