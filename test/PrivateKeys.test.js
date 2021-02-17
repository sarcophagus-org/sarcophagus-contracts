const PrivateKeys = artifacts.require("PrivateKeys")
const { generateKeys } = require("./helpers")

contract("Private Keys", () => {
  let privateKeys

  beforeEach(async () => {
    privateKeys = await PrivateKeys.new()
  })

  it("verifies correct key", async () => {    
    const keys = generateKeys()
    const valid = await privateKeys.keyVerification(keys.private, keys.public)
    expect(valid).to.be.true
  })

  it("verifies incorrect key", async () => { 
    const private = generateKeys().private
    const public = generateKeys().public   
    const valid = await privateKeys.keyVerification(private, public)
    expect(valid).to.be.false
  })
})
