const { deployProxy } = require("@openzeppelin/truffle-upgrades")

const Utils = artifacts.require("Utils")
const PrivateKeys = artifacts.require("PrivateKeys")
const Archaeologists = artifacts.require("Archaeologists")
const Sarcophaguses = artifacts.require("Sarcophaguses")

module.exports = async function (deployer) {
  await deployProxy(Utils, [], { deployer })

  deployer.link(Utils, Archaeologists)
  await deployProxy(Archaeologists, [], { deployer, unsafeAllowLinkedLibraries: true })

  await deployProxy(PrivateKeys, [], { deployer })

  deployer.link(Utils, Sarcophaguses)
  deployer.link(Archaeologists, Sarcophaguses)
  deployer.link(PrivateKeys, Sarcophaguses)
  await deployProxy(Sarcophaguses, [], { deployer, unsafeAllowLinkedLibraries: true })
}
