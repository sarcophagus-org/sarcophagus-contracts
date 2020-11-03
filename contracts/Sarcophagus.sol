// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/Events.sol";
import "./libraries/Types.sol";
import "./libraries/Datas.sol";
import "./libraries/Archaeologists.sol";
import "./libraries/Sarcophaguses.sol";

contract Sarcophagus {
    using SafeMath for uint256;

    IERC20 public sarcoToken;

    Datas.Data data;

    function archaeologistCount() public view returns (uint256) {
        return data.archaeologistAddresses.length;
    }

    function archaeologistAddresses(uint256 index)
        public
        view
        returns (address)
    {
        return data.archaeologistAddresses[index];
    }

    function archaeologists(address addy)
        public
        view
        returns (
            bool exists,
            address archaeologist,
            bytes memory currentPublicKey,
            string memory endpoint,
            address paymentAddress,
            uint256 feePerByte,
            uint256 minimumBounty,
            uint256 minimumDiggingFee,
            uint256 maximumResurrectionTime,
            uint256 freeBond,
            uint256 cursedBond
        )
    {
        Types.Archaeologist memory arch = data.archaeologists[addy];
        return (
            arch.exists,
            arch.archaeologist,
            arch.currentPublicKey,
            arch.endpoint,
            arch.paymentAddress,
            arch.feePerByte,
            arch.minimumBounty,
            arch.minimumDiggingFee,
            arch.maximumResurrectionTime,
            arch.freeBond,
            arch.cursedBond
        );
    }

    function sarcophagusCount() public view returns (uint256) {
        return data.sarcophagusDoubleHashes.length;
    }

    constructor(address _sarcoToken) public {
        sarcoToken = IERC20(_sarcoToken);
        emit Events.Creation(_sarcoToken);
    }

    function registerArchaeologist(
        bytes memory currentPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public returns (bool) {
        return
            Archaeologists.registerArchaeologist(
                data,
                currentPublicKey,
                endpoint,
                paymentAddress,
                feePerByte,
                minimumBounty,
                minimumDiggingFee,
                maximumResurrectionTime,
                freeBond,
                sarcoToken
            );
    }

    function updateArchaeologist(
        string memory endpoint,
        bytes memory currentPublicKey,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public returns (bool) {
        return
            Archaeologists.updateArchaeologist(
                data,
                currentPublicKey,
                endpoint,
                paymentAddress,
                feePerByte,
                minimumBounty,
                minimumDiggingFee,
                maximumResurrectionTime,
                freeBond,
                sarcoToken
            );
    }

    function withdrawBond(uint256 amount) public returns (bool) {
        return Archaeologists.withdrawBond(data, amount, sarcoToken);
    }

    function createSarcophagus(
        string memory name,
        address archaeologist,
        uint256 resurrectionTime,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 assetDoubleHash,
        bytes memory recipientPublicKey
    ) public returns (bool) {
        return
            Sarcophaguses.createSarcophagus(
                data,
                name,
                archaeologist,
                resurrectionTime,
                storageFee,
                diggingFee,
                bounty,
                assetDoubleHash,
                recipientPublicKey,
                sarcoToken
            );
    }

    function updateSarcophagus(
        bytes memory newPublicKey,
        bytes32 assetDoubleHash,
        string memory assetId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        return
            Sarcophaguses.updateSarcophagus(
                data,
                newPublicKey,
                assetDoubleHash,
                assetId,
                v,
                r,
                s,
                sarcoToken
            );
    }

    function cancelSarcophagus(bytes32 assetDoubleHash) public returns (bool) {
        return
            Sarcophaguses.cancelSarcophagus(data, assetDoubleHash, sarcoToken);
    }

    function rewrapSarcophagus(
        bytes32 assetDoubleHash,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty
    ) public returns (bool) {
        return
            Sarcophaguses.rewrapSarcophagus(
                data,
                assetDoubleHash,
                resurrectionTime,
                diggingFee,
                bounty,
                sarcoToken
            );
    }

    function unwrapSarcophagus(bytes32 assetDoubleHash, bytes memory singleHash)
        public
        returns (bool)
    {
        return
            Sarcophaguses.unwrapSarcophagus(
                data,
                assetDoubleHash,
                singleHash,
                sarcoToken
            );
    }

    function accuseArchaeologist(
        bytes32 assetDoubleHash,
        bytes memory singleHash,
        address paymentAddress
    ) public returns (bool) {
        return
            Sarcophaguses.accuseArchaeologist(
                data,
                assetDoubleHash,
                singleHash,
                paymentAddress,
                sarcoToken
            );
    }

    function burySarcophagus(bytes32 assetDoubleHash) public returns (bool) {
        return Sarcophaguses.burySarcophagus(data, assetDoubleHash, sarcoToken);
    }

    function cleanUpSarcophagus(bytes32 assetDoubleHash, address paymentAddress)
        public
        returns (bool)
    {
        return
            Sarcophaguses.cleanUpSarcophagus(
                data,
                assetDoubleHash,
                paymentAddress,
                sarcoToken
            );
    }
}
