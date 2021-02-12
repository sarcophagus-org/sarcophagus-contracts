const { token: _token, sarco: _sarco } = require("./Sarcophagus.test")
const { generatePublicKey } = require("./helpers")

const BN = web3.utils.BN

contract("Sarcophaguses", (accounts) => {
  const [arch, embalmer] = accounts

  let token, sarco

  beforeEach(() => {
    token = _token()
    sarco = _sarco()
  })

  describe("creating a sarcophagus", () => {
    const archBond = new BN(4)

    const resurrectionTime = new BN(Math.floor(Date.now() / 1000) + 100)
    const minBounty = new BN(1)
    const minDiggingFee = new BN(2)
    const storageFee = new BN(1)

    let name = "kingtut"
    let sarcoId = web3.utils.keccak256("sarcoId")
    let archPubKey
    let recipientPubKey

    beforeEach(async () => {
      archPubKey = generatePublicKey()
      recipientPubKey = generatePublicKey()

      await token.transfer(embalmer, (await token.balanceOf(arch)).div(new BN(2)), { from: arch })
      await token.approve(sarco.address, archBond, { from: arch })
      await sarco.registerArchaeologist(archPubKey, "https://test.com/post", arch, 0, minBounty, minDiggingFee, resurrectionTime, archBond, { from: arch })
    })

    describe("getting sarcophagus counts", async () => {
      it("returns next index", async () => {
        await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
        const index = await sarco.createSarcophagus.call(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
        expect(index.eq(new BN(0))).to.be.true
      })

      it("increases the total sarcophagus count", async () => {
        await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
        let count = await sarco.sarcophagusCount()
        expect(count.eq(new BN(0))).to.be.true
        await sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
        count = await sarco.sarcophagusCount()
        expect(count.eq(new BN(1))).to.be.true
      })
    })

    describe("successfully creates sarcophagus", async () => {
      let sarc

      beforeEach(async () => {
        await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
        await sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
        sarc = await sarco.sarcophagus(sarcoId)
      })

      it("has the correct state", async () => {
        expect((new BN(sarc.state)).eq(new BN(1))).to.be.true
      })

      it("has the correct archaeologist", async () => {
        expect(sarc.archaeologist).to.equal(arch)
      })

      it("has the correct archaeologist public key", async () => {
        expect(sarc.archaeologistPublicKey).to.equal("0x" + archPubKey.toString('hex'))
      })

      it("has the correct embalmer", async () => {
        expect(sarc.embalmer).to.equal(embalmer)
      })

      it("has the correct name", async () => {
        expect(sarc.name).to.equal(name)
      })

      it("has the correct resurrection time", async () => {
        expect((new BN(sarc.resurrectionTime)).eq(resurrectionTime)).to.be.true
      })

      it("has the correct resurrection window", async () => {
        expect((new BN(sarc.resurrectionWindow)).eq(new BN(60 * 30 /* 30 mins */))).to.be.true
      })

      it("has empty asset id", async () => {
        expect(sarc.assetId).to.equal("")
      })

      it("has the correct recipient public key", async () => {
        expect(sarc.recipientPublicKey).to.equal("0x" + recipientPubKey.toString('hex'))
      })

      it("has the correct storage fee", async () => {
        expect((new BN(sarc.storageFee)).eq(storageFee)).to.be.true
      })

      it("has the correct digging fee", async () => {
        expect((new BN(sarc.diggingFee)).eq(minDiggingFee)).to.be.true
      })

      it("has the correct bounty", async () => {
        expect((new BN(sarc.bounty)).eq(minBounty)).to.be.true
      })

      it("has the correct cursed bond", async () => {
        expect((new BN(sarc.currentCursedBond)).eq(minBounty.add(minDiggingFee))).to.be.true
      })

      it("has empty private key", async () => {
        expect(sarc.privateKey).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000")
      })
    })
  })
})
