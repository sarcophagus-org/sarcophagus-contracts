// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Types.sol";

library Datas {
    struct Data {
        mapping(address => Types.Archaeologist) archaeologists;
        address[] archaeologistAddresses;
        mapping(address => bytes32[]) archaeologistSuccesses;
        mapping(address => bytes32[]) archaeologistCancels;
        mapping(address => bytes32[]) archaeologistAccusals;
        mapping(address => bytes32[]) archaeologistCleanups;
        mapping(bytes32 => Types.Sarcophagus) sarcophaguses;
        bytes32[] sarcophagusDoubleHashes;
    }
}
