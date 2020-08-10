import { Wallet } from "ethers"

export const pubKey = (wallet: Wallet) => {
  const publicKey = wallet._signingKey().publicKey
  const publicKeyBytes = Buffer.from(publicKey.substring(4), "hex")
  return publicKeyBytes
}
