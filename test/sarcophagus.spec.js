const Sarcophagus = artifacts.require("Sarcophagus")
const truffleAssert = require("truffle-assertions")

contract("sarcophagus", async accounts => {
  let instance

  beforeEach(async () => {
    instance = await Sarcophagus.new()
  })

  describe("registering an archaeologist", () => {
    it("allows anyone to register as an archaeologist", async () => {
      await truffleAssert.passes(
        instance.register.call({ from: accounts[0] }),
        "registration failed"
      )
    })
  })
})
