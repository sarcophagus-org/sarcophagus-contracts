const Sarcophagus = artifacts.require("Sarcophagus")
const truffleAssert = require("truffle-assertions")

contract("sarcophagus", async accounts => {
  let instance

  describe("registers an archaeologist", () => {
    const pubKey = web3.utils.hexToBytes('0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef')

    describe("requires a public key", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      describe("and should fail with a wrong public key length", () => {
        it("very short", async () => {
          await truffleAssert.reverts(
            instance.register(web3.utils.hexToBytes('0x0'), 0, 0, 0),
            "public key must be 64 bytes"
          )
        })

        it("slightly short", async () => { { from: accounts[0] }
          await truffleAssert.reverts(
            instance.register(web3.utils.hexToBytes('0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd'), 0, 0, 0),
            "public key must be 64 bytes"
          )
        })

        it("slightly long", async () => {
          await truffleAssert.reverts(
            instance.register(web3.utils.hexToBytes('0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01'), 0, 0, 0),
            "public key must be 64 bytes"
          )
        })

        it("very long", async () => {
          await truffleAssert.reverts(
            instance.register(web3.utils.hexToBytes('0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'), 0, 0, 0),
            "public key must be 64 bytes"
          )
        })
      })

      describe("and should succeed with a correct public key length", () => {
        it("just right", async () => {
          await instance.register(pubKey, 0, 0, 0)
        })
      })
    })

    describe("requires a minimum bounty value", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("should succeed with a zero value", async () => {
        await instance.register(pubKey, 0, 0, 0)
      })

      it("should succeed with a non-zero value", async () => {
        await instance.register(pubKey, 1, 0, 0)
      })
    })

    describe("requires a minimum digging fee", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("should succeed with a zero value", async () => {
        await instance.register(pubKey, 0, 0, 0)
      })

      it("should succeed with a non-zero value", async () => {
        await instance.register(pubKey, 0, 1, 0)
      })
    })

    describe("requires a maximum resurrection time", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("should succeed with a zero value", async () => {
        await instance.register(pubKey, 0, 0, 0)
      })

      it("should succeed with a non-zero value", async () => {
        await instance.register(pubKey, 0, 0, 1)
      })
    })

    describe("requires a bond", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("should succeed with a zero value", async () => {
        await instance.register(pubKey, 0, 0, 0, { value: 0 })
      })

      it("should succeed with a non-zero value", async () => {
        await instance.register(pubKey, 0, 0, 0, { value: 1 })
      })
    })

    describe("does not allow same key to register twice", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("with with same payment address", async () => {
        await instance.register(pubKey, 0, 0, 0)
        await truffleAssert.reverts(
          instance.register(pubKey, 0, 0, 0),
          "archaeologist already registered"
        )
      })

      it("with different payment addresses", async () => {
        await instance.register(pubKey, 0, 0, 0)
        await truffleAssert.reverts(
          instance.register(pubKey, 0, 0, 0, { from: accounts[1] }),
          "archaeologist already registered"
        )
      })
    })

    describe("allows different keys to register", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      const pubKey2 = web3.utils.hexToBytes('0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdee')

      it("with same payment address", async () => {
        await instance.register(pubKey, 0, 0, 0)
        await instance.register(pubKey2, 0, 0, 0)
      })

      it("with different payment addresss", async () => {
        await instance.register(pubKey, 0, 0, 0)
        await instance.register(pubKey2, 0, 0, 0, { from: accounts[1] })
      })
    })

    describe("returns the number of registered archaeologists", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("when there are none", async () => {
        const archLength = await instance.archaeologistCount()
        assert.equal(archLength, 0)
      })

      it("when there are multiple", async () => {
        const pubKey2 = web3.utils.hexToBytes('0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdee')
        await instance.register(pubKey, 0, 0, 0)
        await instance.register(pubKey2, 0, 0, 0)
        const archLength = await instance.archaeologistCount()
        assert.equal(archLength, 2)
      })
    })

    describe("returns archaeologist public keys", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("spits back the bytes of an archaeologist key given an index", async () => {
        await instance.register(pubKey, 0, 0, 0)
        const archLength = await instance.archaeologistCount()
        const returnedKey = await instance.archaeologistKeys(archLength - 1)
        assert.equal(returnedKey, web3.utils.bytesToHex(pubKey))
      })
    })

    describe("returns data of a registered archaeologist", () => {
      const minBounty = 1
      const minDiggingFee = 2
      const maxResurrectionTime = 3
      const bond = 4

      let archLength, key, arch

      before(async () => {
        instance = await Sarcophagus.new()
        await instance.register(pubKey, minBounty, minDiggingFee, maxResurrectionTime, { value: bond })
        archLength = await instance.archaeologistCount()
        key = await instance.archaeologistKeys(archLength - 1)
        arch = await instance.archaeologists(key)
      })

      it("returns the correct public key", () => {
        assert.equal(web3.utils.bytesToHex(pubKey), key)
      })

      it("returns the correct payment address", () => {
        assert.equal(arch.paymentAddress, accounts[0])
      })

      it("returns the correct minimum bounty", () => {
        assert.equal(arch.minimumBounty, minBounty)
      })

      it("returns the correct minimum digging fee", () => {
        assert.equal(arch.minimumDiggingFee, minDiggingFee)
      })

      it("returns the correct maximum resurrection time", () => {
        assert.equal(arch.maximumResurrectionTime, maxResurrectionTime)
      })
      
      it("returns the correct bond", () => {
        assert.equal(arch.bond, bond)
      })
    })
  
    describe("accumulates the contract value as archaeologists post their bond", () => {
      beforeEach(async () => {
        instance = await Sarcophagus.new()
      })

      it("starts out with a zero balance", async () => {
        const balance = await web3.eth.getBalance(instance.address)
        assert.equal(balance, 0)
      })

      it("adds to the balance when an archaeologist registers", async () => {
        const bond = 1
        await instance.register(pubKey, 0, 0, 0, { value: bond })
        const balance = await web3.eth.getBalance(instance.address)
        assert.equal(balance, bond)
      })

      it("adds to the balance when multiple archaeologists register", async () => {
        const bond1 = 1
        const bond2 = 2
        const pubKey2 = web3.utils.hexToBytes('0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdee')
        await instance.register(pubKey, 0, 0, 0, { value: bond1 })
        await instance.register(pubKey2, 0, 0, 0, { value: bond2 })
        const balance = await web3.eth.getBalance(instance.address)
        assert.equal(balance, bond1 + bond2)
      })
    })
  })
})
