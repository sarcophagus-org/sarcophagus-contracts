// import { expect, use } from 'chai';
// import { ethers } from 'ethers';
// import { deployContract, MockProvider, solidity } from 'ethereum-waffle';
// import Sarcophagus from '../build/Sarcophagus.json';

// use(solidity);

// describe('Sarcophagus', () => {
//   const [wallet, walletTo] = new MockProvider().getWallets();
//   let sarco: ethers.Contract

//   beforeEach(async () => {
//     sarco = await deployContract(wallet, Sarcophagus);
//   });

//   it('Assigns initial balance', async () => {
//     expect(await sarco.balanceOf(wallet.address)).to.equal(1000);
//   });

//   it('Transfer adds amount to destination account', async () => {
//     await sarco.transfer(walletTo.address, 7);
//     expect(await sarco.balanceOf(walletTo.address)).to.equal(7);
//   });

//   it('Transfer emits event', async () => {
//     await expect(sarco.transfer(walletTo.address, 7))
//       .to.emit(sarco, 'Transfer')
//       .withArgs(wallet.address, walletTo.address, 7);
//   });

//   it('Can not transfer above the amount', async () => {
//     await expect(sarco.transfer(walletTo.address, 1007)).to.be.reverted;
//   });

//   it('Can not transfer from empty account', async () => {
//     const tokenFromOtherWallet = sarco.connect(walletTo);
//     await expect(tokenFromOtherWallet.transfer(wallet.address, 1))
//       .to.be.reverted;
//   });

//   it('Calls totalSupply on BasicToken contract', async () => {
//     await sarco.totalSupply();
//     expect('totalSupply').to.be.calledOnContract(sarco);
//   });

//   it('Calls balanceOf with sender address on BasicToken contract', async () => {
//     await sarco.balanceOf(wallet.address);
//     expect('balanceOf').to.be.calledOnContractWith(sarco, [wallet.address]);
//   });
// });