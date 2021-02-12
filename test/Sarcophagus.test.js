const SarcoTokenMock = artifacts.require("SarcoTokenMock")
const Sarcophagus = artifacts.require("Sarcophagus")
const Archaeologists = artifacts.require("Archaeologists")
const PrivateKeys = artifacts.require("PrivateKeys")
const Sarcophaguses = artifacts.require("Sarcophaguses")
const Utils = artifacts.require("Utils")

let _sarco, _token

beforeEach(async () => {
  _token = await SarcoTokenMock.new()

  const utilsLibrary = await Utils.new()

  await Archaeologists.link("Utils", utilsLibrary.address)
  const archaeologistsLibrary = await Archaeologists.new()

  const privateKeysLibrary = await PrivateKeys.new()

  await Sarcophaguses.link("Utils", utilsLibrary.address)
  await Sarcophaguses.link("Archaeologists", archaeologistsLibrary.address)
  await Sarcophaguses.link("PrivateKeys", privateKeysLibrary.address)
  const sarcophagusesLibrary = await Sarcophaguses.new()

  await Sarcophagus.link("Archaeologists", archaeologistsLibrary.address)
  await Sarcophagus.link("Sarcophaguses", sarcophagusesLibrary.address)

  _sarco = await Sarcophagus.new(_token.address)
})

const token = () => _token
const sarco = () => _sarco

module.exports = { token, sarco }
