import { expect, use } from "chai"
import { Contract, BigNumber } from "ethers"
import { deployContract, MockProvider, solidity } from "ethereum-waffle"
import Token from "../build/SarcophagusToken.json"
import Sarcophagus from "../build/Sarcophagus.json"
import { pubKey } from "./helpers"

use(solidity)

describe("Sarcophagus", () => {
  const provider = new MockProvider()
  const [wallet, wallet2] = provider.getWallets()
  let sarco: Contract, token: Contract

  beforeEach(async () => {
    token = await deployContract(wallet, Token, [BigNumber.from(100).pow(18), "Sarcophagus Token", "SARCO"])
    sarco = await deployContract(wallet, Sarcophagus, [token.address])
  })

  describe("updates an archaeologist", () => {
    describe("doesn't work if the archaeologist is not registered", () => {
      it("cannot update archaeologist", async () => {
        await expect(sarco.callStatic.update(wallet.address, 0, 0, 0, 0)).to.be.revertedWith("archaeologist has not been registered yet")
      })

      it("cannot withdrawal free bond", async () => {
        await expect(sarco.callStatic.withdrawalBond(0)).to.be.revertedWith("archaeologist has not been registered yet")
      })
    })

    describe("does work if the archaeologist is registered", () => {
      beforeEach(async () => {
        await token.approve(sarco.address, 1)
        await sarco.register(pubKey(wallet), wallet.address, 0, 0, 0, 1)
      })

      describe("cannot update the public key", () => {
        it("doesn't even accept public key as an input", async () => {
          await expect(sarco.callStatic.update(pubKey(wallet))).to.be.reverted
        })
      })

      describe("updates the payment address", () => {
        it("allows a new payment address to be set", async () => {
          const ogArch = await sarco.archaeologists(wallet.address)
          expect(ogArch.paymentAddress).to.equal(wallet.address)
          const result = await sarco.callStatic.update(wallet2.address, 0, 0, 0, 0)
          expect(result).to.be.true
          await sarco.update(wallet2.address, 0, 0, 0, 0)
          const arch = await sarco.archaeologists(wallet.address)
          expect(arch.paymentAddress).to.equal(wallet2.address)
        })
      })

      describe("updates the minimum bounty", () => {
        it("allows the minimum bounty to be updated", async () => {
          const ogArch = await sarco.archaeologists(wallet.address)
          expect(ogArch.minimumBounty).to.equal(0)
          const result = await sarco.callStatic.update(wallet.address, 1, 0, 0, 0)
          expect(result).to.be.true
          await sarco.update(wallet.address, 1, 0, 0, 0)
          const arch = await sarco.archaeologists(wallet.address)
          expect(arch.minimumBounty).to.equal(1)
        })
      })

      describe("updates the minimum digging fee", () => {
        it("allows the minimum digging fee to be updated", async () => {
          const ogArch = await sarco.archaeologists(wallet.address)
          expect(ogArch.minimumDiggingFee).to.equal(0)
          const result = await sarco.callStatic.update(wallet.address, 0, 1, 0, 0)
          expect(result).to.be.true
          await sarco.update(wallet.address, 0, 1, 0, 0)
          const arch = await sarco.archaeologists(wallet.address)
          expect(arch.minimumDiggingFee).to.equal(1)
        })
      })

      describe("updates the maximum resurrection time", () => {
        it("allows the maximum resurrection time to be updated", async () => {
          const ogArch = await sarco.archaeologists(wallet.address)
          expect(ogArch.maximumResurrectionTime).to.equal(0)
          const result = await sarco.callStatic.update(wallet.address, 0, 0, 1, 0)
          expect(result).to.be.true
          await sarco.update(wallet.address, 0, 0, 1, 0)
          const arch = await sarco.archaeologists(wallet.address)
          expect(arch.maximumResurrectionTime).to.equal(1)
        })
      })

      describe("adds more free bond", () => {
        it("allows the user to add more free bond", async () => {
          const ogArch = await sarco.archaeologists(wallet.address)
          expect(ogArch.freeBond).to.equal(1)
          await token.approve(sarco.address, 3)
          const result = await sarco.callStatic.update(wallet.address, 0, 0, 0, 2)
          expect(result).to.be.true
          await sarco.update(wallet.address, 0, 0, 0, 2)
          const arch = await sarco.archaeologists(wallet.address)
          expect(arch.freeBond).to.equal(3)
        })

        it("does not allow an integer overflow", async () => {
          // i don't know how to test for this in javascript
        })

        it("updates the contract balance", async () => {
          const balance = await token.balanceOf(sarco.address)
          expect(balance).to.equal(1)
          await token.approve(sarco.address, 3)
          await sarco.update(wallet.address, 0, 0, 0, 2)
          const newBalance = await token.balanceOf(sarco.address)
          expect(newBalance).to.equal(3)
        })
      })

      describe("withdraws free bond from an archaeologist", () => {
        it("does not allow a withdrawal if not enough free bond", async () => {
          await expect(sarco.callStatic.withdrawalBond(2)).to.be.revertedWith("requested withdrawal amount is greater than free bond")
        })

        describe("enough free bond", () => {
          it("allows a withdrawal of full free bond amount", async () => {
            const result = await sarco.callStatic.withdrawalBond(1)
            expect(result).to.be.true
            await sarco.withdrawalBond(1)
            const arch = await sarco.archaeologists(wallet.address)
            expect(arch.freeBond).to.equal(0)
          })

          it("allows a withdrawal of less than full free bond amount", async () => {
            await token.approve(sarco.address, 3)
            const result = await sarco.callStatic.update(wallet.address, 0, 0, 0, 2)
            expect(result).to.be.true
            await sarco.update(wallet.address, 0, 0, 0, 2)
            await sarco.withdrawalBond(1)
            const arch = await sarco.archaeologists(wallet.address)
            expect(arch.freeBond).to.equal(2)
          })
        })
        
        it("reduces the amount of money on the contract", async () => {
          const balance = await token.balanceOf(sarco.address)
          expect(balance).to.equal(1)
          await sarco.withdrawalBond(1)
          const newBalance = await token.balanceOf(sarco.address)
          expect(newBalance).to.equal(0)
        })
      })
    })
  })
})
