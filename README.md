# Sarcophagus Smart Contracts

This repository contains the smart contract code and deployment scripts for the Sarcophagus Token, and the Sarcophagus system smart contract.

To either do local development, or deploy the contracts, you'll need to set some configuration values.

```sh
$ cp .env.example .env
```

Then open up `.env` and edit as you see fit. The default values are fine for local development.

If you're going to be deploying to public blockchain networks (testnets, or mainnet), you need to enter a private key into the corresponding `<NETWORK>_PK` environment variable (starting with `0x`). Make sure this key has some ETH, to pay for the transaction fees! Also enter a URL for an ethereum provider into the `<NETWORK>_PROVIDER` environment variable.

Next, install the project's dependencies

```sh
$ npm install
```

Finally, you'll need to compile the contracts

```sh
$ npm run compile
```

Now you're all set up for doing local development or deploying the contracts to a public network.

## Local Development

"Running" the project consists of spinning up a local blockchain and deploying the contracts to that blockchain.

Once you've done that, you'll be able to use any Ethereum wallet to connect to your local blockchain and interact with those contracts.

Start a local blockchain via

```sh
$ npm run develop
```

and then within the new Truffle Console, deploy the contracts by typing `migrate`

```
truffle(develop)> migrate
```

In your console output you'll see both the Sarcophagus (Mock) Token and the Sarcopahgus contract being deployed, their transaction hashes, and their addresses.

## Testing

To run the tests, run

```sh
$ npm run test
```

## Deployment

Deployments ("migrations") happen via `truffle`.

To deploy to the Goerli testnet, execute

```sh
$ npx truffle migrate --network goerli
```

To deploy to the Mainnet, execute

```sh
$ npx truffle migrate --network mainnet
```

Note: be sure to set your deployer private key, and provider, in `.env`

To deploy to other networks, add the relevant network block into `truffle-config.js` and execute

```sh
$ npx truffle migrate --network <yourNewNetwork>
```

## Public Deployments

The contracts are currently deployed on public networks.

### Goerli

**Libraries**

| Name | Address |
| --- | --- |
| Utils | `0x17001EDf972E3b0a51718bee91413b30CDfe5D73` |
| Archaeologists | `0xE1d999A9a14872025D9C2f951f8f13c1ED6A585d` |
| PrivateKeys | `0x32A7B3c72b13e670107788740e218F2B0FeD8D88` |
| Sarcophaguses | `0x5af7270d1b5A88Eb433B997b031F73BD34476eFc` |

**Contracts**

| Name | Address |
| --- | --- |
| Migrations | `0x04577D0ed278f503fbdcF5aE77439eAa6a89cB44` |
| Sarcophagus | `0xb6E8176987F6e5010e1908aaBA0369054000a344` |

## Final notes

Any time you make any changes to the smart contracts, don't forget to re-compile before executing any of the above commands

```sh
$ npm run compile
```

If you've got a local development environment running (via `npm run develop`), you'll want to stop and restart that.
