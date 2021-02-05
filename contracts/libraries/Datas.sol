// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Types.sol";

library Datas {
    struct Data {
        // archaeologists
        address[] archaeologistAddresses;
        mapping(address => Types.Archaeologist) archaeologists;

        // archaeologist stats
        mapping(address => bytes32[]) archaeologistSuccesses;
        mapping(address => bytes32[]) archaeologistCancels;
        mapping(address => bytes32[]) archaeologistAccusals;
        mapping(address => bytes32[]) archaeologistCleanups;

        // archaeologist key control
        mapping(bytes => bool) archaeologistUsedKeys;

        // sarcophaguses
        bytes32[] sarcophagusDoubleHashes;
        mapping(bytes32 => Types.Sarcophagus) sarcophaguses;

        // sarcophagus ownerships
        mapping(address => bytes32[]) embalmerSarcophaguses;
        mapping(address => bytes32[]) archaeologistSarcophaguses;
        mapping(address => bytes32[]) recipientSarcophaguses;
    }
}
