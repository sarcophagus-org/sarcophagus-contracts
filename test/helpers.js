const Wallet = require('ethereumjs-wallet')

const generatePublicKey = () => {
  const account = web3.eth.accounts.create()
  const privateKey = account.privateKey.substring(2)
  const privateKeyBuffer = Buffer.from(privateKey, "hex")
  const wallet = Wallet.default.fromPrivateKey(privateKeyBuffer)
  const publicKeyBytes = wallet.getPublicKey()
  return publicKeyBytes
}

module.exports = { generatePublicKey }
