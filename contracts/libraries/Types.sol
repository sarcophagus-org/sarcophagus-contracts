// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A collection of defined structs
 * @notice This library defines the various data models that the Sarcophagus
 * system uses
 */
library Types {
    struct Archaeologist {
        bool exists;
        bytes currentPublicKey;
        string endpoint;
        address paymentAddress;
        uint256 feePerByte;
        uint256 minimumBounty;
        uint256 minimumDiggingFee;
        uint256 maximumResurrectionTime;
        uint256 freeBond;
        uint256 cursedBond;
    }

    enum SarcophagusStates {DoesNotExist, Exists, Done}

    struct Sarcophagus {
        SarcophagusStates state;
        address archaeologist;
        bytes archaeologistPublicKey;
        address embalmer;
        string name;
        uint256 resurrectionTime;
        uint256 resurrectionWindow;
        string assetId;
        bytes recipientPublicKey;
        uint256 storageFee;
        uint256 diggingFee;
        uint256 bounty;
        uint256 currentCursedBond;
        bytes32 privateKey;
    }
}
