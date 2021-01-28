const SarcoTokenMock = artifacts.require("SarcoTokenMock")
const Sarcophagus = artifacts.require("Sarcophagus")
const Archaeologists = artifacts.require("Archaeologists")
const PrivateKeys = artifacts.require("PrivateKeys")
const Sarcophaguses = artifacts.require("Sarcophaguses")
const Utils = artifacts.require("Utils")

const truffleAssert = require("truffle-assertions")
const { generatePublicKey } = require("./helpers")
const BN = web3.utils.BN

contract("Sarcophagus Manager", (accounts) => {
  const [wallet, wallet2] = accounts
  let sarco, token

  beforeEach(async () => {
    token = await SarcoTokenMock.new()
    
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
    
    sarco = await Sarcophagus.new(token.address)
  })

  describe("registers an archaeologist", () => {
    describe("requires a public key", () => {
      describe("and should fail with a wrong public key length", () => {
        it("very short", async () => {
          const smallest = Buffer.from("00", "hex")
          expect(smallest).to.have.lengthOf(1)
          await truffleAssert.reverts(
            sarco.registerArchaeologist.call(smallest, "https://test.com/post", wallet2, 0, 0, 0, 0, 0),
            "public key must be 64 bytes"
          )
        })

        it("slightly short", async () => {
          const publickKey = generatePublicKey()
          const smaller = publickKey.subarray(0, publickKey.length - 1)
          expect(smaller).to.have.lengthOf(63)
          await truffleAssert.reverts(
            sarco.registerArchaeologist.call(smaller, "https://test.com/post", wallet2, 0, 0, 0, 0, 0),
            "public key must be 64 bytes"
          )
        })

        it("slightly long", async () => {
          const bigger = Buffer.concat([generatePublicKey(), Buffer.from("00", "hex")])
          expect(bigger).to.have.lengthOf(65)
          await truffleAssert.reverts(
            sarco.registerArchaeologist.call(bigger, "https://test.com/post", wallet2, 0, 0, 0, 0, 0),
            "public key must be 64 bytes"
          )
        })

        it("very long", async () => {
          const publickKey = generatePublicKey()
          const biggest = Buffer.concat([publickKey, publickKey])
          expect(biggest).to.have.lengthOf(128)
          await truffleAssert.reverts(
            sarco.registerArchaeologist.call(biggest, "https://test.com/post", wallet2, 0, 0, 0, 0, 0),
            "public key must be 64 bytes"
          )
        })
      })

      describe("and should succeed with a correct public key length", () => {
        it("just right", async () => {
          const publicKey = generatePublicKey()
          const register = await sarco.registerArchaeologist.call(publicKey, "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
          expect(register).to.equal(true)
          await sarco.registerArchaeologist(publicKey, "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
          const count = await sarco.archaeologistCount()
          expect(count.toNumber()).to.equal(1)
        })
      })
    })

    describe("requires a minimum bounty value", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed with a non-zero value", async () => {
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 1, 0, 0, 0)
        expect(ret).to.be.true
      })
    })

    describe("requires a minimum digging fee", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed with a non-zero value", async () => {
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 1, 0, 0)
        expect(ret).to.be.true
      })
    })

    describe("requires a maximum resurrection time", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed with a non-zero value", async () => {
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 1, 0)
        expect(ret).to.be.true
      })
    })

    describe("requires a bond", () => {
      it("should succeed with a zero value", async () => {
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
        expect(ret).to.be.true
      })

      it("should succeed wit4h a non-zero value", async () => {
        await token.approve(sarco.address, 1)
        const ret = await sarco.registerArchaeologist.call(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 1)
        expect(ret).to.be.true
      })
    })

    describe("does not allow same key to register twice", () => {
      it("with with same payment address", async () => {
        const publicKey = generatePublicKey()
        await sarco.registerArchaeologist(publicKey, "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
        await truffleAssert.reverts(
          sarco.registerArchaeologist.call(publicKey, "https://test.com/post", wallet2, 0, 0, 0, 0, 0),
          "archaeologist has already been registered"
        )
      })

      it("with different payment addresses", async () => {
        const publicKey = generatePublicKey()
        await sarco.registerArchaeologist(publicKey, "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
        await truffleAssert.reverts(
          sarco.registerArchaeologist.call(publicKey, "https://test.com/post", wallet, 0, 0, 0, 0, 0),
          "archaeologist has already been registered"
        )
      })
    })

    describe("allows different keys to register", () => {
      it("with same payment address", async () => {
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet, 0, 0, 0, 0, 0)
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet, 0, 0, 0, 0, 0, { from: wallet2 })
        const count = await sarco.archaeologistCount()
        expect(count.toNumber()).to.equal(2)
      })

      it("with different payment address", async () => {
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet, 0, 0, 0, 0, 0)
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 0, { from: wallet2 })
        const count = await sarco.archaeologistCount()
        expect(count.toNumber()).to.equal(2)
      })
    })

    describe("returns the number of registered archaeologists", () => {
      it("when there are none", async () => {
        const count = await sarco.archaeologistCount()
        expect(count.toNumber()).to.equal(0)
      })

      it("when there are multiple", async () => {
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet, 0, 0, 0, 0, 0)
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 0, { from: wallet2 })
        const count = await sarco.archaeologistCount()
        expect(count.toNumber()).to.equal(2)
      })
    })

    describe("returns archaeologist address", () => {
      it("spits back the archaeologist addresss given an index", async () => {
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, 0)
        const archLength = await sarco.archaeologistCount()
        const returnedAddress = await sarco.archaeologistAddresses(archLength.sub(new BN(1)))
        expect(returnedAddress).is.equal(wallet)
      })
    })

    describe("returns data of a registered archaeologist", () => {
      const minBounty = 1
      const minDiggingFee = 2
      const maxResurrectionTime = 3
      const bond = 4
      const paymentAddress = wallet2

      let archLength, addressFromContract, arch

      beforeEach(async () => {
        await token.approve(sarco.address, bond)
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", paymentAddress, 0, minBounty, minDiggingFee, maxResurrectionTime, bond)
        archLength = await sarco.archaeologistCount()
        addressFromContract = await sarco.archaeologistAddresses(archLength.sub(new BN(1)))
        arch = await sarco.archaeologists(addressFromContract)
      })

      it("returns the correct public key", () => {
        expect(addressFromContract).to.equal(wallet)
      })

      it("returns the correct payment address", () => {
        expect(arch.paymentAddress).to.equal(paymentAddress)
      })

      it("returns the correct minimum bounty", () => {
        expect(arch.minimumBounty.toNumber()).to.equal(minBounty)
      })

      it("returns the correct minimum digging fee", () => {
        expect(arch.minimumDiggingFee.toNumber()).to.equal(minDiggingFee)
      })

      it("returns the correct maximum resurrection time", () => {
        expect(arch.maximumResurrectionTime.toNumber()).to.equal(maxResurrectionTime)
      })

      it("returns the correct bond", () => {
        expect(arch.freeBond.toNumber()).to.equal(bond)
      })
    })

    describe("accumulates the contract value as archaeologists post their bond", () => {
      it("starts out with a zero balance", async () => {
        const balance = await token.balanceOf(sarco.address)
        expect(balance.toNumber()).to.equal(0)
      })

      it("adds to the balance when an archaeologist registers", async () => {
        const ogBalance = await token.balanceOf(sarco.address)
        const bond = new BN(1)
        await token.approve(sarco.address, bond)
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet, 0, 0, 0, 0, bond)
        const newBalance = await token.balanceOf(sarco.address)
        expect(newBalance.toNumber()).to.equal(ogBalance.add(bond).toNumber())
      })

      it("adds to the balance when multiple archaeologists register", async () => {
        const ogBalance = await token.balanceOf(sarco.address)
        const bond1 = 1
        const bond2 = 2
        await token.transfer(wallet2, 2)
        await token.approve(sarco.address, bond1)
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet, 0, 0, 0, 0, bond1)
        await token.approve(sarco.address, bond2, { from: wallet2 })
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet2, 0, 0, 0, 0, bond2, { from: wallet2 })
        const newBalance = await token.balanceOf(sarco.address)
        expect(newBalance.sub(ogBalance).toNumber()).to.equal(bond1 + bond2)
      })
    })
  })

  describe("updates an archaeologist", () => {
    describe("doesn't work if the archaeologist is not registered", () => {
      it("cannot update archaeologist", async () => {
        await truffleAssert.reverts(
          sarco.updateArchaeologist.call("https://test.com/post", generatePublicKey(), wallet, 0, 0, 0, 0, 0),
          "archaeologist has not been registered yet"
        )
      })

      it("cannot withdraw free bond", async () => {
        await truffleAssert.reverts(
          sarco.withdrawBond.call(0),
          "archaeologist has not been registered yet"
        )
      })
    })

    describe("does work if the archaeologist is registered", () => {
      beforeEach(async () => {
        await token.approve(sarco.address, 1)
        await sarco.registerArchaeologist(generatePublicKey(), "https://test.com/post", wallet, 0, 0, 0, 0, 1)
      })

      describe("updates the payment address", () => {
        it("allows a new payment address to be set", async () => {
          const ogArch = await sarco.archaeologists(wallet)
          expect(ogArch.paymentAddress).to.equal(wallet)
          const publicKey = generatePublicKey()
          const result = await sarco.updateArchaeologist.call("https://test.com/post", publicKey, wallet2, 0, 0, 0, 0, 0)
          expect(result).to.be.true
          await sarco.updateArchaeologist("https://test.com/post", publicKey, wallet2, 0, 0, 0, 0, 0)
          const arch = await sarco.archaeologists(wallet)
          expect(arch.paymentAddress).to.equal(wallet2)
        })
      })

      describe("updates the minimum bounty", () => {
        it("allows the minimum bounty to be updated", async () => {
          const ogArch = await sarco.archaeologists(wallet)
          expect(ogArch.minimumBounty.toNumber()).to.equal(0)
          const publicKey = generatePublicKey()
          const result = await sarco.updateArchaeologist.call("https://test.com/post", publicKey, wallet, 0, 1, 0, 0, 0)
          expect(result).to.be.true
          await sarco.updateArchaeologist("https://test.com/post", publicKey, wallet, 0, 1, 0, 0, 0)
          const arch = await sarco.archaeologists(wallet)
          expect(arch.minimumBounty.toNumber()).to.equal(1)
        })
      })

      describe("updates the minimum digging fee", () => {
        it("allows the minimum digging fee to be updated", async () => {
          const ogArch = await sarco.archaeologists(wallet)
          expect(ogArch.minimumDiggingFee.toNumber()).to.equal(0)
          const publicKey = generatePublicKey()
          const result = await sarco.updateArchaeologist.call("https://test.com/post", publicKey, wallet, 0, 0, 1, 0, 0)
          expect(result).to.be.true
          await sarco.updateArchaeologist("https://test.com/post", publicKey, wallet, 0, 0, 1, 0, 0)
          const arch = await sarco.archaeologists(wallet)
          expect(arch.minimumDiggingFee.toNumber()).to.equal(1)
        })
      })

      describe("updates the maximum resurrection time", () => {
        it("allows the maximum resurrection time to be updated", async () => {
          const ogArch = await sarco.archaeologists(wallet)
          expect(ogArch.maximumResurrectionTime.toNumber()).to.equal(0)
          const publicKey = generatePublicKey()
          const result = await sarco.updateArchaeologist.call("https://test.com/post", publicKey, wallet, 0, 0, 0, 1, 0)
          expect(result).to.be.true
          await sarco.updateArchaeologist("https://test.com/post", publicKey, wallet, 0, 0, 0, 1, 0)
          const arch = await sarco.archaeologists(wallet)
          expect(arch.maximumResurrectionTime.toNumber()).to.equal(1)
        })
      })

      describe("adds more free bond", () => {
        it("allows the user to add more free bond", async () => {
          const ogArch = await sarco.archaeologists(wallet)
          expect(ogArch.freeBond.toNumber()).to.equal(1)
          await token.approve(sarco.address, 3)
          const publicKey = generatePublicKey()
          const result = await sarco.updateArchaeologist.call("https://test.com/post", publicKey, wallet, 0, 0, 0, 0, 2)
          expect(result).to.be.true
          await sarco.updateArchaeologist("https://test.com/post", publicKey, wallet, 0, 0, 0, 0, 2)
          const arch = await sarco.archaeologists(wallet)
          expect(arch.freeBond.toNumber()).to.equal(3)
        })

        it("does not allow an integer overflow", async () => {
          // i don't know how to test for this in javascript
        })

        it("updates the contract balance", async () => {
          const balance = await token.balanceOf(sarco.address)
          expect(balance.toNumber()).to.equal(1)
          await token.approve(sarco.address, 3)
          await sarco.updateArchaeologist("https://test.com/post", generatePublicKey(), wallet, 0, 0, 0, 0, 2)
          const newBalance = await token.balanceOf(sarco.address)
          expect(newBalance.toNumber()).to.equal(3)
        })
      })

      describe("withdraws free bond from an archaeologist", () => {
        it("does not allow a withdrawal if not enough free bond", async () => {
          await truffleAssert.reverts(
            sarco.withdrawBond.call(2),
            "archaeologist does not have enough free bond"
          )
        })

        describe("enough free bond", () => {
          it("allows a withdrawal of full free bond amount", async () => {
            const result = await sarco.withdrawBond.call(1)
            expect(result).to.be.true
            await sarco.withdrawBond(1)
            const arch = await sarco.archaeologists(wallet)
            expect(arch.freeBond.toNumber()).to.equal(0)
          })

          it("allows a withdrawal of less than full free bond amount", async () => {
            await token.approve(sarco.address, 3)
            const publicKey = generatePublicKey()
            const result = await sarco.updateArchaeologist.call("https://test.com/post", publicKey, wallet, 0, 0, 0, 0, 2)
            expect(result).to.be.true
            await sarco.updateArchaeologist("https://test.com/post", publicKey, wallet, 0, 0, 0, 0, 2)
            await sarco.withdrawBond(1)
            const arch = await sarco.archaeologists(wallet)
            expect(arch.freeBond.toNumber()).to.equal(2)
          })
        })
        
        it("reduces the amount of money on the contract", async () => {
          const balance = await token.balanceOf(sarco.address)
          expect(balance.toNumber()).to.equal(1)
          await sarco.withdrawBond(1)
          const newBalance = await token.balanceOf(sarco.address)
          expect(newBalance.toNumber()).to.equal(0)
        })
      })
    })
  })
})
