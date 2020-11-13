import { expect, use } from "chai"
import { Contract } from "ethers"
import { deployContract, MockProvider, solidity } from "ethereum-waffle"
import PrivateKeys from "../build/PrivateKeys.json"

use(solidity)

describe("Private Keys", () => {
  const provider = new MockProvider()
  const [wallet] = provider.getWallets()
  let privateKeys: Contract;

  beforeEach(async () => {
    privateKeys = await deployContract(wallet, PrivateKeys)
  })

  it("verifies correct key", async () => {    
    // this private key derived this public key
    const privKey = Buffer.from([137, 238, 6, 7, 23, 118, 40, 25, 176, 223, 165, 1, 209, 243, 194, 70, 240, 89, 253, 112, 161, 181, 76, 114, 49, 230, 23, 179, 37, 148, 229, 85])
    const pubKey = Buffer.from([233, 45, 247, 2, 81, 26, 248, 250, 30, 239, 17, 42, 103, 144, 255, 102, 13, 145, 39, 231, 109, 107, 253, 154, 66, 224, 30, 50, 163, 116, 223, 60, 208, 214, 158, 193, 103, 118, 26, 81, 147, 29, 173, 153, 211, 187, 161, 129, 43, 25, 132, 34, 67, 4, 80, 121, 41, 188, 19, 250, 232, 211, 246, 137])

    const valid = await privateKeys.keyVerification(privKey, pubKey)
    expect(valid).to.be.true
  })

  it("verifies incorrect key", async () => {    
    // changed last byte of privKey
    const privKey = Buffer.from([137, 238, 6, 7, 23, 118, 40, 25, 176, 223, 165, 1, 209, 243, 194, 70, 240, 89, 253, 112, 161, 181, 76, 114, 49, 230, 23, 179, 37, 148, 229, 84])
    const pubKey = Buffer.from([233, 45, 247, 2, 81, 26, 248, 250, 30, 239, 17, 42, 103, 144, 255, 102, 13, 145, 39, 231, 109, 107, 253, 154, 66, 224, 30, 50, 163, 116, 223, 60, 208, 214, 158, 193, 103, 118, 26, 81, 147, 29, 173, 153, 211, 187, 161, 129, 43, 25, 132, 34, 67, 4, 80, 121, 41, 188, 19, 250, 232, 211, 246, 137])

    const valid = await privateKeys.keyVerification(privKey, pubKey)
    expect(valid).to.be.false
  })
})
