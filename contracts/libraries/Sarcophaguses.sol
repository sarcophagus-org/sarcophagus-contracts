// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Utils.sol";
import "./Events.sol";
import "./Types.sol";
import "./Datas.sol";
import "./Archaeologists.sol";

library Sarcophaguses {
    using SafeMath for uint256;

    function sarcophagusState(
        Types.SarcophagusStates sarcState,
        Types.SarcophagusStates state
    ) public pure {
        string memory error = "sarcophagus already exists";
        if (state == Types.SarcophagusStates.Exists)
            error = "sarcophagus does not exist or is not active";
        require(sarcState == state, error);
    }

    function wipeSarcophagusMoney(Types.Sarcophagus storage sarc) public {
        sarc.storageFee = 0;
        sarc.diggingFee = 0;
        sarc.bounty = 0;
        sarc.currentCursedBond = 0;
    }

    function splitSendDone(
        Datas.Data storage data,
        address archAddress,
        address paymentAddress,
        Types.Sarcophagus storage sarc,
        IERC20 sarcoToken
    ) public returns (uint256, uint256) {
        uint256 halfToEmbalmer = sarc.currentCursedBond.div(2);
        uint256 halfToSender = sarc.currentCursedBond.sub(halfToEmbalmer);
        sarcoToken.transfer(
            sarc.embalmer,
            sarc.bounty.add(sarc.diggingFee).add(halfToEmbalmer)
        );
        sarcoToken.transfer(paymentAddress, halfToSender);

        Archaeologists.reduceCursedBond(
            data,
            archAddress,
            sarc.currentCursedBond
        );

        wipeSarcophagusMoney(sarc);

        sarc.state = Types.SarcophagusStates.Done;
    }

    function createSarcophagus(
        Datas.Data storage data,
        string memory name,
        bytes memory archaeologistPublicKey,
        uint256 resurrectionTime,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 assetDoubleHash,
        bytes memory recipientPublicKey,
        IERC20 sarcoToken
    ) public returns (bool) {
        address archAddress = Utils.addressFromPublicKey(
            archaeologistPublicKey
        );
        Archaeologists.archaeologistExists(data, archAddress, true);
        Utils.publicKeyLength(recipientPublicKey);
        sarcophagusState(
            data.sarcophaguses[assetDoubleHash].state,
            Types.SarcophagusStates.DoesNotExist
        );
        Utils.resurrectionInFuture(resurrectionTime);
        Types.Archaeologist storage arch = data.archaeologists[archAddress];
        Utils.withinArchaeologistLimits(
            resurrectionTime,
            diggingFee,
            bounty,
            arch.maximumResurrectionTime,
            arch.minimumDiggingFee,
            arch.minimumBounty
        );

        sarcoToken.transferFrom(
            msg.sender,
            address(this),
            diggingFee.add(bounty).add(storageFee)
        );

        // TODO: implment an algorithm to figure this out
        uint256 cursedBondAmount = diggingFee.add(bounty);

        Archaeologists.lockUpBond(data, archAddress, cursedBondAmount);

        Types.Sarcophagus memory sarc = Types.Sarcophagus({
            state: Types.SarcophagusStates.Exists,
            archaeologist: archaeologistPublicKey,
            embalmer: msg.sender,
            name: name,
            resurrectionTime: resurrectionTime,
            resurrectionWindow: Utils.getGracePeriod(resurrectionTime),
            assetId: "",
            recipientPublicKey: recipientPublicKey,
            storageFee: storageFee,
            diggingFee: diggingFee,
            bounty: bounty,
            currentCursedBond: cursedBondAmount
        });

        data.sarcophaguses[assetDoubleHash] = sarc;
        data.sarcophagusDoubleHashes.push(assetDoubleHash);

        emit Events.CreateSarcophagus(
            assetDoubleHash,
            sarc.archaeologist,
            sarc.embalmer,
            sarc.name,
            sarc.resurrectionTime,
            sarc.resurrectionWindow,
            sarc.storageFee,
            sarc.diggingFee,
            sarc.bounty,
            sarc.recipientPublicKey,
            sarc.currentCursedBond
        );

        return true;
    }

    function updateSarcophagus(
        Datas.Data storage data,
        bytes32 assetDoubleHash,
        string memory assetId,
        uint8 v,
        bytes32 r,
        bytes32 s,
        IERC20 sarcoToken
    ) public returns (bool) {
        Types.Sarcophagus storage sarc = data.sarcophaguses[assetDoubleHash];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);
        Utils.sarcophagusUpdater(sarc.embalmer);
        Utils.assetIdsCheck(sarc.assetId, assetId);
        address archAddress = Utils.addressFromPublicKey(sarc.archaeologist);
        Utils.signatureCheck(assetId, v, r, s, archAddress);

        sarc.assetId = assetId;

        Types.Archaeologist memory arch = data.archaeologists[archAddress];
        sarcoToken.transfer(arch.paymentAddress, sarc.storageFee);
        sarc.storageFee = 0;

        emit Events.UpdateSarcophagus(assetDoubleHash, assetId);

        return true;
    }

    function cancelSarcophagus(
        Datas.Data storage data,
        bytes32 assetDoubleHash,
        IERC20 sarcoToken
    ) public returns (bool) {
        Types.Sarcophagus storage sarc = data.sarcophaguses[assetDoubleHash];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);
        Utils.confirmAssetIdNotSet(sarc.assetId);
        Utils.sarcophagusUpdater(sarc.embalmer);

        address archAddress = Utils.addressFromPublicKey(sarc.archaeologist);
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        sarcoToken.transfer(sarc.embalmer, sarc.bounty.add(sarc.storageFee));
        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee);

        Archaeologists.freeUpBond(data, archAddress, sarc.currentCursedBond);
        wipeSarcophagusMoney(sarc);

        data.archaeologistCancels[archAddress].push(assetDoubleHash);

        // TODO: update cursed bond calculation ? maybe

        emit Events.CancelSarcophagus(assetDoubleHash);

        return true;
    }

    function rewrapSarcophagus(
        Datas.Data storage data,
        bytes32 assetDoubleHash,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty,
        IERC20 sarcoToken
    ) public returns (bool) {
        Types.Sarcophagus storage sarc = data.sarcophaguses[assetDoubleHash];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);
        Utils.sarcophagusUpdater(sarc.embalmer);
        Utils.resurrectionInFuture(sarc.resurrectionTime);
        Utils.resurrectionInFuture(resurrectionTime);

        address archAddress = Utils.addressFromPublicKey(sarc.archaeologist);
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        Utils.withinArchaeologistLimits(
            resurrectionTime,
            diggingFee,
            bounty,
            arch.maximumResurrectionTime,
            arch.minimumDiggingFee,
            arch.minimumBounty
        );

        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee);

        // TODO: implement an algorithm to figure this out
        uint256 cursedBondAmount = diggingFee.add(bounty);

        if (cursedBondAmount > sarc.currentCursedBond) {
            uint256 diff = cursedBondAmount.sub(sarc.currentCursedBond);
            Archaeologists.lockUpBond(data, archAddress, diff);
        } else if (cursedBondAmount < sarc.currentCursedBond) {
            uint256 diff = sarc.currentCursedBond.sub(cursedBondAmount);
            Archaeologists.freeUpBond(data, archAddress, diff);
        }

        uint256 gracePeriod = Utils.getGracePeriod(resurrectionTime);

        sarc.resurrectionTime = resurrectionTime;
        sarc.diggingFee = diggingFee;
        sarc.bounty = bounty;
        sarc.currentCursedBond = cursedBondAmount;
        sarc.resurrectionWindow = gracePeriod;

        emit Events.RewrapSarcophagus(
            sarc.assetId,
            assetDoubleHash,
            resurrectionTime,
            gracePeriod,
            diggingFee,
            bounty,
            cursedBondAmount
        );

        return true;
    }

    function unwrapSarcophagus(
        Datas.Data storage data,
        bytes32 assetDoubleHash,
        bytes memory singleHash,
        IERC20 sarcoToken
    ) public returns (bool) {
        Types.Sarcophagus storage sarc = data.sarcophaguses[assetDoubleHash];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);
        Utils.unwrapTime(sarc.resurrectionTime, sarc.resurrectionWindow);

        Utils.hashCheck(assetDoubleHash, singleHash);

        address archAddress = Utils.addressFromPublicKey(sarc.archaeologist);
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        sarcoToken.transfer(
            arch.paymentAddress,
            sarc.diggingFee.add(sarc.bounty)
        );

        Archaeologists.freeUpBond(data, archAddress, sarc.currentCursedBond);
        wipeSarcophagusMoney(sarc);

        sarc.state = Types.SarcophagusStates.Done;

        data.archaeologistSuccesses[archAddress].push(assetDoubleHash);

        // TODO: update cursed bond calculation

        emit Events.UnwrapSarcophagus(
            sarc.assetId,
            assetDoubleHash,
            singleHash
        );

        return true;
    }

    function accuseArchaeologist(
        Datas.Data storage data,
        bytes32 assetDoubleHash,
        bytes memory singleHash,
        address paymentAddress,
        IERC20 sarcoToken
    ) public returns (bool) {
        Types.Sarcophagus storage sarc = data.sarcophaguses[assetDoubleHash];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);
        Utils.resurrectionInFuture(sarc.resurrectionTime);
        Utils.hashCheck(assetDoubleHash, singleHash);

        address archAddress = Utils.addressFromPublicKey(sarc.archaeologist);

        (uint256 halfToSender, uint256 halfToEmbalmer) = splitSendDone(
            data,
            archAddress,
            paymentAddress,
            sarc,
            sarcoToken
        );

        data.archaeologistAccusals[archAddress].push(assetDoubleHash);

        // TODO: update cursed bond calculation

        emit Events.AccuseArchaeologist(
            assetDoubleHash,
            msg.sender,
            halfToSender,
            halfToEmbalmer
        );

        return true;
    }

    function burySarcophagus(
        Datas.Data storage data,
        bytes32 assetDoubleHash,
        IERC20 sarcoToken
    ) public returns (bool) {
        Types.Sarcophagus storage sarc = data.sarcophaguses[assetDoubleHash];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        Utils.sarcophagusUpdater(sarc.embalmer);
        Utils.resurrectionInFuture(sarc.resurrectionTime);

        address archAddress = Utils.addressFromPublicKey(sarc.archaeologist);
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        Archaeologists.freeUpBond(data, archAddress, sarc.currentCursedBond);

        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee);
        wipeSarcophagusMoney(sarc);

        sarc.resurrectionTime = 2**256 - 1;
        sarc.state = Types.SarcophagusStates.Done;

        // TODO: calculate new bond multiplier ? maybe

        emit Events.BurySarcophagus(assetDoubleHash);

        return true;
    }

    function cleanUpSarcophagus(
        Datas.Data storage data,
        bytes32 assetDoubleHash,
        address paymentAddress,
        IERC20 sarcoToken
    ) public returns (bool) {
        Types.Sarcophagus storage sarc = data.sarcophaguses[assetDoubleHash];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        require(
            sarc.resurrectionTime.add(sarc.resurrectionWindow) <
                block.timestamp,
            "sarcophagus resurrection period must be in the past"
        );

        address archAddress = Utils.addressFromPublicKey(sarc.archaeologist);

        (uint256 halfToSender, uint256 halfToEmbalmer) = splitSendDone(
            data,
            archAddress,
            paymentAddress,
            sarc,
            sarcoToken
        );

        data.archaeologistCleanups[archAddress].push(assetDoubleHash);

        // TODO: calculate new bond multiplier

        emit Events.CleanUpSarcophagus(
            assetDoubleHash,
            msg.sender,
            halfToSender,
            halfToEmbalmer
        );

        return true;
    }
}
