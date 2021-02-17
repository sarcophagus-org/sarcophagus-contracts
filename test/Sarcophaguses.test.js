const truffleAssert = require("truffle-assertions")
const { advanceBlock, latestTime, increaseTimeTo } = require("truffle-test-helpers")
const { token: _token, sarco: _sarco } = require("./Sarcophagus.test")
const { generateKeys, deriveAddress, signPubKeyAndAssetId } = require("./helpers")

const toBN = web3.utils.toBN

contract("Sarcophaguses", (accounts) => {
  const [arch, embalmer] = accounts

  let token, sarco

  const archBond = toBN(10)

  const maxResurrectionTime = 60 * 60 // 1 hour
  const resurrectionTimeDelta = 100
  const minBounty = toBN(1)
  const minDiggingFee = toBN(2)
  const storageFee = toBN(1)

  let name = "kingtut"
  let singleHash = Buffer.from(web3.utils.keccak256("sarcoId").substring(2), "hex")
  let sarcoId = Buffer.from(web3.utils.keccak256(singleHash).substring(2), "hex")
  let archPubKey
  let recipientPubKey
  let resurrectionTime

  beforeEach(async () => {
    token = _token()
    sarco = _sarco()
    archPubKey = generateKeys().public
    recipientPubKey = generateKeys().public
    await advanceBlock()
    resurrectionTime = toBN((await latestTime()) + resurrectionTimeDelta)
  })

  describe("creating a sarcophagus", () => {
    describe("unsuccessful creation", () => {
      describe("with unregistered archaeologist", () => {
        it("fails", async () => {
          await truffleAssert.reverts(
            sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer }),
            "archaeologist has not been registered yet"
          )
        })
      })

      describe("with archaeologist without free bond", () => {
        beforeEach(async () => {
          await sarco.registerArchaeologist(archPubKey, "https://test.com/post", arch, 0, minBounty, minDiggingFee, maxResurrectionTime, 0, { from: arch })
        })

        it("fails", async () => {
          await truffleAssert.reverts(
            sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer }),
            "archaeologist does not have enough free bond"
          )
        })
      })

      describe("with valid archaeologist", () => {
        beforeEach(async () => {
          await token.transfer(embalmer, (await token.balanceOf(arch)).div(toBN(2)), { from: arch })
          await token.approve(sarco.address, archBond, { from: arch })
          await sarco.registerArchaeologist(archPubKey, "https://test.com/post", arch, 0, minBounty, minDiggingFee, maxResurrectionTime, archBond, { from: arch })
        })

        describe("invalid recipient public key", () => {
          it("fails", async () => {
            await truffleAssert.reverts(
              sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey.subarray(0, recipientPubKey.length - 1), { from: embalmer }),
              "public key must be 64 bytes"
            )
          })
        })

        describe("sarcophagus already exists", () => {
          beforeEach(async () => {
            await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
            await sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
          })

          it("fails", async () => {
            await truffleAssert.reverts(
              sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer }),
              "sarcophagus already exists"
            )
          })
        })

        describe("resurrection in the past", () => {
          it("fails", async () => {
            await truffleAssert.reverts(
              sarco.createSarcophagus(name, arch, toBN(Math.floor(Date.now() / 1000) - 100), storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer }),
              "resurrection time must be in the future"
            )
          })
        })

        describe("invalid resurrection time, for archaeologist", () => {
          it("fails", async () => {
            await truffleAssert.reverts(
              sarco.createSarcophagus(name, arch, resurrectionTime.add(toBN(60 * 60 * 2 /* 2 hours */)), storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer }),
              "resurrection time too far in the future"
            )
          })
        })

        describe("invalid digging fee, for archaeologist", () => {
          it("fails", async () => {
            await truffleAssert.reverts(
              sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee.sub(toBN(1)), minBounty, sarcoId, recipientPubKey, { from: embalmer }),
              "digging fee is too low"
            )
          })
        })

        describe("invalid bounty, for archaeologist", () => {
          it("fails", async () => {
            await truffleAssert.reverts(
              sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty.sub(toBN(1)), sarcoId, recipientPubKey, { from: embalmer }),
              "bounty is too low"
            )
          })
        })

        describe("embalmer hasn't approved SARCO token transfer", () => {
          it("fails", async () => {
            await truffleAssert.reverts(
              sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer }),
              "ERC20: transfer amount exceeds allowance"
            )
          })
        })
      })
    })

    describe("successful creation", () => {
      beforeEach(async () => {
        await token.transfer(embalmer, (await token.balanceOf(arch)).div(toBN(2)), { from: arch })
        await token.approve(sarco.address, archBond, { from: arch })
        await sarco.registerArchaeologist(archPubKey, "https://test.com/post", arch, 0, minBounty, minDiggingFee, maxResurrectionTime, archBond, { from: arch })
      })

      describe("getting sarcophagus counts", async () => {
        it("returns next index", async () => {
          await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
          const index = await sarco.createSarcophagus.call(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
          expect(index.eq(toBN(0))).to.be.true
        })

        it("increases the total sarcophagus count", async () => {
          await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
          let count = await sarco.sarcophagusCount()
          expect(count.eq(toBN(0))).to.be.true
          await sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
          count = await sarco.sarcophagusCount()
          expect(count.eq(toBN(1))).to.be.true
        })
      })

      describe("successfully creates sarcophagus", async () => {
        let index, originalSarcoBalance

        beforeEach(async () => {
          originalSarcoBalance = await token.balanceOf(sarco.address)
          await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
          index = await sarco.createSarcophagus.call(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
          await sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
        })

        describe("contains the correct properties", () => {
          let sarc

          beforeEach(async () => {
            sarc = await sarco.sarcophagus(sarcoId)
          })

          it("has the correct state", async () => {
            expect((toBN(sarc.state)).eq(toBN(1))).to.be.true
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
            expect((toBN(sarc.resurrectionTime)).eq(resurrectionTime)).to.be.true
          })

          it("has the correct resurrection window", async () => {
            expect((toBN(sarc.resurrectionWindow)).eq(toBN(60 * 30 /* 30 mins */))).to.be.true
          })

          it("has empty asset id", async () => {
            expect(sarc.assetId).to.equal("")
          })

          it("has the correct recipient public key", async () => {
            expect(sarc.recipientPublicKey).to.equal("0x" + recipientPubKey.toString('hex'))
          })

          it("has the correct storage fee", async () => {
            expect((toBN(sarc.storageFee)).eq(storageFee)).to.be.true
          })

          it("has the correct digging fee", async () => {
            expect((toBN(sarc.diggingFee)).eq(minDiggingFee)).to.be.true
          })

          it("has the correct bounty", async () => {
            expect((toBN(sarc.bounty)).eq(minBounty)).to.be.true
          })

          it("has the correct cursed bond", async () => {
            expect((toBN(sarc.currentCursedBond)).eq(minBounty.add(minDiggingFee))).to.be.true
          })

          it("has empty private key", async () => {
            expect(sarc.privateKey).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000")
          })
        })

        describe("exists in the correct data structures", () => {
          it("is in the identifiers array", async () => {
            const id = await sarco.sarcophagusIdentifier(index)
            expect(id).to.equal("0x" + sarcoId.toString("hex"))
          })

          it("is in the embalmer's array", async () => {
            const id = await sarco.embalmerSarcophagusIdentifier(embalmer, index)
            expect(id).to.equal("0x" + sarcoId.toString("hex"))
          })

          it("is in the archaeologist's array", async () => {
            const id = await sarco.archaeologistSarcophagusIdentifier(arch, index)
            expect(id).to.equal("0x" + sarcoId.toString("hex"))
          })

          it("is in the recipient's array", async () => {
            const recipientAddress = deriveAddress(recipientPubKey)
            const id = await sarco.recipientSarcophagusIdentifier(recipientAddress, index)
            expect(id).to.equal("0x" + sarcoId.toString("hex"))
          })
        })

        describe("token balances", () => {
          it("transfered correct number of SARCO tokens to contract", async () => {
            expect((await token.balanceOf(sarco.address)).eq(originalSarcoBalance.add(minDiggingFee.add(minBounty).add(storageFee)))).to.be.true
          })
        })
      })
    })
  })

  describe("cancelling a sarcophagus", () => {
    let archPrivKey

    beforeEach(async () => {
      const keys = generateKeys()
      archPubKey = keys.public
      archPrivKey = keys.private

      await token.transfer(embalmer, (await token.balanceOf(arch)).div(toBN(2)), { from: arch })
      await token.approve(sarco.address, archBond, { from: arch })
      await sarco.registerArchaeologist(archPubKey, "https://test.com/post", arch, 0, minBounty, minDiggingFee, maxResurrectionTime, archBond, { from: arch })
    })

    describe("unsuccessful cancel", () => {
      describe("without an existing sarcophagus", () => {
        it("throws error if sarcophagus does not exist", async () => {
          await truffleAssert.reverts(
            sarco.cancelSarcophagus(sarcoId, { from: embalmer }),
            "sarcophagus does not exist or is not active"
          )
        })
      })

      describe("with an existing sarcophagus", () => {
        beforeEach(async () => {
          await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
          await sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
        })

        describe("sarcophagus has been updated", () => {
          let newPubKey
          let assetId

          beforeEach(async () => {
            newPubKey = generateKeys().public
            assetId = "abc"

            const signature = signPubKeyAndAssetId(newPubKey, assetId, arch)
            await sarco.updateSarcophagus(newPubKey, sarcoId, assetId, signature.v, signature.r, signature.s, { from: embalmer })
          })

          describe("sarcophagus is active", () => {
            it("throws error if sarcophagus already has an asset id", async () => {
              await truffleAssert.reverts(
                sarco.cancelSarcophagus(sarcoId, { from: embalmer }),
                "assetId has already been set"
              )
            })
          })

          describe("sarcophagus has been unwrapped", () => {
            beforeEach(async () => {
              await increaseTimeTo(resurrectionTime.add(toBN(1)))
              await sarco.unwrapSarcophagus(sarcoId, archPrivKey)
            })

            it("fails", async () => {
              await truffleAssert.reverts(
                sarco.cancelSarcophagus(sarcoId, { from: embalmer }),
                "sarcophagus does not exist or is not active"
              )
            })
          })

          describe("sarcophagus has been cleaned up", () => {
            beforeEach(async () => {
              await increaseTimeTo(resurrectionTime.add(toBN(maxResurrectionTime)))
              await sarco.cleanUpSarcophagus(sarcoId, embalmer)
            })

            it("fails", async () => {
              await truffleAssert.reverts(
                sarco.cancelSarcophagus(sarcoId, { from: embalmer }),
                "sarcophagus does not exist or is not active"
              )
            })
          })

          describe("sarcophagus has been accused", () => {
            beforeEach(async () => {
              await sarco.accuseArchaeologist(sarcoId, singleHash, embalmer)
            })

            it("fails", async () => {
              await truffleAssert.reverts(
                sarco.cancelSarcophagus(sarcoId, { from: embalmer }),
                "sarcophagus does not exist or is not active"
              )
            })
          })

          describe("sarcophagus has been buried", () => {
            beforeEach(async () => {
              await sarco.burySarcophagus(sarcoId, { from: embalmer })
            })

            it("fails", async () => {
              await truffleAssert.reverts(
                sarco.cancelSarcophagus(sarcoId, { from: embalmer }),
                "sarcophagus does not exist or is not active"
              )
            })
          })
        })

        describe("sarcophagus has not been updated", () => {
          it("throws error if the wrong account attempts to cancel", async () => {
            await truffleAssert.reverts(
              sarco.cancelSarcophagus(sarcoId, { from: arch }),
              "sarcophagus cannot be updated by account"
            )
          })
        })
      })
    })

    describe("successful cancel", () => {
      let sarc
      let embalmerTokenBalanceBefore, embalmerTokenBalanceAfter
      let archTokenBalanceBefore, archTokenBalanceAfter
      let archFreeBondBefore, archFreeBondAfter

      beforeEach(async () => {
        await token.approve(sarco.address, storageFee + minDiggingFee + minBounty, { from: embalmer })
        await sarco.createSarcophagus(name, arch, resurrectionTime, storageFee, minDiggingFee, minBounty, sarcoId, recipientPubKey, { from: embalmer })
        embalmerTokenBalanceBefore = await token.balanceOf(embalmer)
        archTokenBalanceBefore = await token.balanceOf(arch)
        archFreeBondBefore = toBN((await sarco.archaeologists(arch)).freeBond)
        await sarco.cancelSarcophagus(sarcoId, { from: embalmer })
        sarc = await sarco.sarcophagus(sarcoId)
        embalmerTokenBalanceAfter = await token.balanceOf(embalmer)
        archTokenBalanceAfter = await token.balanceOf(arch)
        archFreeBondAfter = toBN((await sarco.archaeologists(arch)).freeBond)
      })

      it("is in correct state", () => {
        expect(toBN(sarc.state).eq(toBN(2))).to.be.true
      })

      it("is marked against the archaeologist", async () => {
        expect(await sarco.archaeologistCancelsIdentifier(arch, 0)).to.equal("0x" + sarcoId.toString("hex"))
      })

      it("returns the right amount of SARCO to the embalmer", () => {
        expect(embalmerTokenBalanceAfter.sub(embalmerTokenBalanceBefore).eq(minBounty.add(storageFee))).to.be.true
      })

      it("returns the right amount of SARCO to the archaeologist", () => {
        expect(archTokenBalanceAfter.sub(archTokenBalanceBefore).eq(minDiggingFee)).to.be.true
      })

      it("frees up the correct amount of archaeologist bond", () => {
        expect(archFreeBondAfter.sub(archFreeBondBefore).eq(minDiggingFee.add(minBounty))).to.be.true
      })
    })
  })
})
