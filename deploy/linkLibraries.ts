import { Signer } from "ethers"
import { deployContract, link } from "ethereum-waffle"
import Utils from "../build/Utils.json"
import Archaeologists from "../build/Archaeologists.json"
import Sarcophaguses from "../build/Sarcophaguses.json"
import Sarcophagus from "../build/Sarcophagus.json"
import PrivateKeys from "../build/PrivateKeys.json"

export const linkLibraries = async (wallet: Signer, logger: Function | null, environment: string | null) => {
  const utilsLibrary = await deployContract(wallet, Utils, [])
  if (logger && environment) logger(environment, "utils library", utilsLibrary)

  const privateKeysLibrary = await deployContract(wallet, PrivateKeys, [])
  if (logger && environment) logger(environment, "privateKeys library", privateKeysLibrary)

  link(Archaeologists, 'contracts/libraries/Utils.sol:Utils', utilsLibrary.address)
  const archsLibrary = await deployContract(wallet, Archaeologists, [])
  if (logger && environment) logger(environment, "archaeologists library", archsLibrary)

  link(Sarcophaguses, 'contracts/libraries/Utils.sol:Utils', utilsLibrary.address)
  link(Sarcophaguses, 'contracts/libraries/Archaeologists.sol:Archaeologists', archsLibrary.address)
  link(Sarcophaguses, 'contracts/libraries/PrivateKeys.sol:PrivateKeys', archsLibrary.address)
  const sarcsLibrary = await deployContract(wallet, Sarcophaguses, [])
  if (logger && environment) logger(environment, "sarcophaguses library", sarcsLibrary)

  link(Sarcophagus, 'contracts/libraries/Archaeologists.sol:Archaeologists', archsLibrary.address)
  link(Sarcophagus, 'contracts/libraries/Sarcophaguses.sol:Sarcophaguses', sarcsLibrary.address)

  return Sarcophagus
}
