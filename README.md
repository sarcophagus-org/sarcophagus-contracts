# Sarcophagus Core

[![Discord](https://img.shields.io/discord/753398645507883099?color=768AD4&label=discord)](https://discord.com/channels/753398645507883099/)
[![Twitter](https://img.shields.io/twitter/follow/sarcophagusio?style=social)](https://twitter.com/sarcophagusio)

Sarcophagus is a decentralized dead man's switch built on Ethereum and Arweave.

## Overview

This repository contains the smart contracts (and corresponding deployment scripts) that power the Sarcophagus system.

## Configuration

To work with the contracts you'll need to set some configuration values:

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

The contracts are currently deployed on public networks. Please refer to the `deployed` directory for details.
## Additional Tips

If you make changes to the contracts, re-compile before executing any of the above commands:

```sh
$ npm run compile
```

In addition, If you're running on a local development environment (via `npm run develop`), you'll want to stop and restart it to reflect the changes.

## Community

[![Discord](https://img.shields.io/discord/753398645507883099?color=768AD4&label=discord)](https://discord.com/channels/753398645507883099/)
[![Twitter](https://img.shields.io/twitter/follow/sarcophagusio?style=social)](https://twitter.com/sarcophagusio)

We can also be found on [Telegram](https://t.me/sarcophagusio).

Made with :skull: and proudly decentralized.
