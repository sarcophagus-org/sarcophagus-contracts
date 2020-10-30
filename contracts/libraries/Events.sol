// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library Events {
    event Creation(address sarcophagusContract);

    event RegisterArchaeologist(
        address archaeologist,
        bytes currentPublicKey,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 bond
    );

    event UpdateArchaeologist(
        address archaeologist,
        bytes currentPublicKey,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 addedBond
    );

    event WithdrawalFreeBond(address archaeologist, uint256 withdrawnBond);

    event CreateSarcophagus(
        bytes32 assetDoubleHash,
        bytes archaeologist,
        address embalmer,
        string name,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes recipientPublicKey,
        uint256 cursedBond
    );

    event UpdateSarcophagus(bytes32 assetDoubleHash, string assetId);

    event CancelSarcophagus(bytes32 assetDoubleHash);

    event RewrapSarcophagus(
        string assetId,
        bytes32 assetDoubleHash,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 diggingFee,
        uint256 bounty,
        uint256 cursedBond
    );

    event UnwrapSarcophagus(
        string assetId,
        bytes32 assetDoubleHash,
        bytes singleHash
    );

    event AccuseArchaeologist(
        bytes32 assetDoubleHash,
        address accuser,
        uint256 accuserBondReward,
        uint256 embalmerBondReward
    );

    event BurySarcophagus(bytes32 assetDoubleHash);

    event CleanUpSarcophagus(
        bytes32 assetDoubleHash,
        address cleaner,
        uint256 cleanerBondReward,
        uint256 embalmerBondReward
    );
}
