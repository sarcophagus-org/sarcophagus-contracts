import { expect, use } from 'chai'
import { Contract, ethers } from 'ethers'
import { deployContract, MockProvider, solidity } from 'ethereum-waffle'
import Token from '../build/SarcophagusToken.json'
import Sarcophagus from '../build/Sarcophagus.json'
import { pubKey } from './helpers'

use(solidity)

describe('Sarcophagus', () => {
  const provider = new MockProvider()
  const [wallet, wallet2] = provider.getWallets()
  let sarco: Contract, token: Contract

  beforeEach(async () => {
    token = await deployContract(wallet, Token, [ethers.BigNumber.from(100).pow(18), "Sarcophagus Token", "SARCO"])
    sarco = await deployContract(wallet, Sarcophagus, [token.address])
  })

  describe("registers an archaeologist", () => {
    describe("requires a public key", () => {
      describe("and should fail with a wrong public key length", () => {
        it("very short", async () => {
          const smallest = Buffer.from("00", "hex")
          expect(smallest).to.have.lengthOf(1)
          await expect(sarco.callStatic.register(smallest, wallet2.address, 0, 0, 0, 0)).to.be.revertedWith("public key must be 64 bytes")
        })

        it("slightly short", async () => {
          const smaller = pubKey(wallet).subarray(0, pubKey(wallet).length - 1)
          expect(smaller).to.have.lengthOf(63)
          await expect(sarco.callStatic.register(smaller, wallet2.address, 0, 0, 0, 0)).to.be.revertedWith("public key must be 64 bytes")
        })

        it("slightly long", async () => {
          const bigger = Buffer.concat([pubKey(wallet), Buffer.from("00", "hex")])
          expect(bigger).to.have.lengthOf(65)
          await expect(sarco.callStatic.register(bigger, wallet2.address, 0, 0, 0, 0)).to.be.revertedWith("public key must be 64 bytes")
        })

        it("very long", async () => {
          const biggest = Buffer.concat([pubKey(wallet), pubKey(wallet)])
          expect(biggest).to.have.lengthOf(128)
          await expect(sarco.callStatic.register(biggest, wallet2.address, 0, 0, 0, 0)).to.be.revertedWith("public key must be 64 bytes")
        })
      })

      describe("and should succeed with a correct public key length", () => {
        it("just right", async () => {
          const register = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
          expect(register).to.equal(true)
          await sarco.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
          const count = await sarco.archaeologistCount()
          expect(count).to.equal(1)
        })
      })
    })

    describe("requires the archaeologist transaction initiator and public key match", () => {
      it("fails when the public key does not derive the transaction's msg.sender", async () => {
        sarco = sarco.connect(wallet)
        await expect(sarco.callStatic.register(pubKey(wallet2), wallet.address, 0, 0, 0, 0)).to.be.revertedWith("transaction address must have been derived from public key input")
      })

      it("succeeds when the public key derives the transaction's msg.sender", async () => {
        sarco = sarco.connect(wallet)
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, 0)
        const count = await sarco.archaeologistCount()
        expect(count).to.equal(1)
      })
    })

    describe("requires a minimum bounty value", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed with a non-zero value", async () => {
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 1, 0, 0, 0)
        expect(ret).to.be.true
      })
    })

    describe("requires a minimum digging fee", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed with a non-zero value", async () => {
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 1, 0, 0)
        expect(ret).to.be.true
      })
    })

    describe("requires a maximum resurrection time", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed with a non-zero value", async () => {
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 1, 0)
        expect(ret).to.be.true
      })
    })

    describe("requires a bond", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed wit4h a non-zero value", async () => {
        await token.approve(sarco.address, 1)
        const ret = await sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 0, 1)
        expect(ret).to.be.true
      })
    })

    describe("does not allow same key to register twice", () => {
      it("with with same payment address", async () => {
        await sarco.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
        await expect(sarco.callStatic.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)).to.be.revertedWith("archaeologist already registered")
      })

      it("with different payment addresses", async () => {
        await sarco.register(pubKey(wallet), wallet2.address, 0, 0, 0, 0)
        await expect(sarco.callStatic.register(pubKey(wallet), wallet.address, 0, 0, 0, 0)).to.be.revertedWith("archaeologist already registered")
      })
    })

    describe("allows different keys to register", () => {
      it("with same payment address", async () => {
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, 0)
        sarco = sarco.connect(wallet2)
        await sarco.register(pubKey(wallet2), wallet.address, 0, 0, 0, 0)
        const count = await sarco.archaeologistCount()
        expect(count).to.equal(2)
      })

      it("with different payment addresss", async () => {
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, 0)
        sarco = sarco.connect(wallet2)
        await sarco.register(pubKey(wallet2), wallet2.address, 0, 0, 0, 0)
        const count = await sarco.archaeologistCount()
        expect(count).to.equal(2)
      })
    })

    describe("returns the number of registered archaeologists", () => {
      it("when there are none", async () => {
        const count = await sarco.archaeologistCount()
        expect(count).to.equal(0)
      })

      it("when there are multiple", async () => {
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, 0)
        sarco = sarco.connect(wallet2)
        await sarco.register(pubKey(wallet2), wallet2.address, 0, 0, 0, 0)
        const count = await sarco.archaeologistCount()
        expect(count).to.equal(2)
      })
    })

    describe("returns archaeologist public keys", () => {
      it("spits back the bytes of an archaeologist key given an index", async () => {
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, 0)
        const archLength = await sarco.archaeologistCount()
        const returnedAddress = await sarco.archaeologistAddresses(archLength - 1)
        expect(returnedAddress).is.equal(wallet.address)
      })
    })

    describe("returns data of a registered archaeologist", () => {
      const minBounty = 1
      const minDiggingFee = 2
      const maxResurrectionTime = 3
      const bond = 4
      const paymentAddress = wallet2.address

      let archLength: number, addressFromContract: string, arch: any

      beforeEach(async () => {
        await token.approve(sarco.address, bond)
        await sarco.register(pubKey(wallet), paymentAddress, minBounty, minDiggingFee, maxResurrectionTime, bond)
        archLength = await sarco.archaeologistCount()
        addressFromContract = await sarco.archaeologistAddresses(archLength - 1)
        arch = await sarco.archaeologists(addressFromContract)
      })

      it("returns the correct public key", () => {
        expect(addressFromContract).to.equal(wallet.address)
      })

      it("returns the correct payment address", () => {
        expect(arch.paymentAddress).to.equal(paymentAddress)
      })

      it("returns the correct minimum bounty", () => {
        expect(arch.minimumBounty).to.equal(minBounty)
      })

      it("returns the correct minimum digging fee", () => {
        expect(arch.minimumDiggingFee).to.equal(minDiggingFee)
      })

      it("returns the correct maximum resurrection time", () => {
        expect(arch.maximumResurrectionTime).to.equal(maxResurrectionTime)
      })

      it("returns the correct bond", () => {
        expect(arch.freeBond).to.equal(bond)
      })
    })

    describe("accumulates the contract value as archaeologists post their bond", () => {
      it("starts out with a zero balance", async () => {
        const balance = await token.balanceOf(sarco.address)
        expect(balance).to.equal(0)
      })

      it("adds to the balance when an archaeologist registers", async () => {
        const ogBalance = await token.balanceOf(sarco.address)
        const bond = 1
        await token.approve(sarco.address, bond)
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, bond)
        const newBalance = await token.balanceOf(sarco.address)
        expect(newBalance).to.equal(ogBalance.add(bond))
      })

      it("adds to the balance when multiple archaeologists register", async () => {
        const ogBalance = await token.balanceOf(sarco.address)
        const bond1 = 1
        const bond2 = 2
        await token.transfer(wallet2.address, 2)
        await token.approve(sarco.address, bond1)
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, bond1)
        token = token.connect(wallet2)
        sarco = sarco.connect(wallet2)
        await token.approve(sarco.address, bond2)
        await sarco.register(pubKey(wallet2), wallet2.address, 0, 0, 0, bond2)
        const newBalance = await token.balanceOf(sarco.address)
        expect(newBalance.sub(ogBalance)).to.equal(bond1 + bond2)
      })
    })
  })
})
