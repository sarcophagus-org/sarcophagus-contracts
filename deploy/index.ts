import { Contract, providers, BigNumber, Signer, Wallet } from "ethers"
import { deployContract } from "ethereum-waffle"
import Token from "../build/SarcophagusToken.json"
import SarcophagusManager from "../build/SarcophagusManager.json"

require("dotenv").config()

const logContractData = (environment: string, name: string, contract: Contract) => {
  console.log("")
  console.log("         !!! DEPLOYED !!!")
  console.log("network:", environment)
  console.log("name:   ", name)
  console.log("tx hash:", contract.deployTransaction.hash)
  console.log("address:", contract.address)
  console.log("")
}

const deployWithSigner = async (environment: string, signer: Signer) => {
  if (!process.env.SARCOPHAGUS_TOKEN_SUPPLY) throw new Error("Set SARCOPHAGUS_TOKEN_SUPPLY")
  if (!process.env.SARCOPHAGUS_TOKEN_NAME) throw new Error("Set SARCOPHAGUS_TOKEN_NAME")
  if (!process.env.SARCOPHAGUS_TOKEN_SYMBOL) throw new Error("Set SARCOPHAGUS_TOKEN_SYMBOL")

  const supplyNumber: number = parseInt(process.env.SARCOPHAGUS_TOKEN_SUPPLY, 10)
  const supply: BigNumber = BigNumber.from(supplyNumber).mul(BigNumber.from(10).pow(18))
  const name: string = process.env.SARCOPHAGUS_TOKEN_NAME
  const symbol: string = process.env.SARCOPHAGUS_TOKEN_SYMBOL
  const token: Contract = await deployContract(signer, Token, [supply, name, symbol])
  logContractData(environment, name, token)

  const sarco: Contract = await deployContract(signer, SarcophagusManager, [token.address])
  logContractData(environment, "Sarcophagus", sarco)
}

const ticker = (environment: string, timeout: number, signer: Signer) => {
  console.log("")
  console.log(`in ${environment.toUpperCase()} mode`)
  console.log(`deploying to ${environment.toUpperCase()} blockchain`)
  console.log("")
  console.log("did you remember to recompile?")
  console.log("")
  console.log(`continuing in ${timeout} seconds`)
  console.log("")

  return new Promise(resolve => {
    const tick = setInterval(async () => {
      process.stdout.write(`${timeout}... `);
  
      timeout--
      if (timeout >= 0) return
      
      console.log("")
      console.log("")
      clearInterval(tick)
  
      await deployWithSigner(environment, signer)
      resolve()
    }, 1000)
  })
}

const publicDeploy = async (envName: string, envPrivateKey: string | undefined, timeout: number) => {
  if (!envPrivateKey) throw new Error(`Set ${envName.toUpperCase()}_DEPLOYMENT_PRIVATE_KEY`)
  const provider: providers.BaseProvider = providers.getDefaultProvider(envName)
  const signer: Signer = new Wallet(envPrivateKey, provider)
  await ticker(envName, timeout, signer)
}

const deploy = async (args?: string[]) => {
  let timeout: number = parseInt(process.env.DEPLOYMENT_TIMEOUT || "10", 10)
  if (timeout < 0) timeout = 0
  if (args?.includes("--no-wait")) timeout = 0

  if (!args?.includes("public")) {
    const provider: providers.JsonRpcProvider = new providers.JsonRpcProvider(`http://localhost:${process.env.DEVELOPMENT_BLOCKCHAIN_PORT}`)
    const signer: Signer = provider.getSigner()
    await ticker("development", timeout, signer)
  } else {
    let deployed = false

    if (args?.includes("--goerli")) {
      deployed = true
      await publicDeploy("goerli", process.env.GOERLI_DEPLOYMENT_PRIVATE_KEY, timeout)
    }
  
    if (args?.includes("--ropsten")) {
      deployed = true
      await publicDeploy("ropsten", process.env.ROPSTEN_DEPLOYMENT_PRIVATE_KEY, timeout)
    }
  
    if (args?.includes("--kovan")) {
      deployed = true
      await publicDeploy("kovan", process.env.KOVAN_DEPLOYMENT_PRIVATE_KEY, timeout)
    }
  
    if (args?.includes("--rinkeby")) {
      deployed = true
      await publicDeploy("rinkeby", process.env.RINKEBY_DEPLOYMENT_PRIVATE_KEY, timeout)
    }
  
    if (args?.includes("--mainnet")) {
      deployed = true
      await publicDeploy("mainnet", process.env.MAINNET_DEPLOYMENT_PRIVATE_KEY, 10)
    }

    if (!deployed){
      console.log("To perform a public deployemnt, pass in one or more public network flags")
      console.log("Options are:")
      console.log("  --goerli")
      console.log("  --ropsten")
      console.log("  --kovan")
      console.log("  --rinkeby")
      console.log("  --mainnet")
    }
  }
}

deploy(process.argv)
