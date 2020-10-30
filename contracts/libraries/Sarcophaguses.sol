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
    ) internal pure {
        string memory error = "sarcophagus already exists";
        if (state == Types.SarcophagusStates.Exists)
            error = "sarcophagus does not exist or is not active";
        require(sarcState == state, error);
    }

    function wipeSarcophagusMoney(Types.Sarcophagus storage sarc) private {
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
    ) private returns (uint256, uint256) {
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
        address archaeologist,
        uint256 resurrectionTime,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 assetDoubleHash,
        bytes memory recipientPublicKey,
        IERC20 sarcoToken
    ) public returns (bool) {
        Archaeologists.archaeologistExists(data, archaeologist, true);
        Utils.publicKeyLength(recipientPublicKey);
        sarcophagusState(
            data.sarcophaguses[assetDoubleHash].state,
            Types.SarcophagusStates.DoesNotExist
        );
        Utils.resurrectionInFuture(resurrectionTime);
        Types.Archaeologist storage arch = data.archaeologists[archaeologist];
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

        Archaeologists.lockUpBond(data, archaeologist, cursedBondAmount);

        Types.Sarcophagus memory sarc = Types.Sarcophagus({
            state: Types.SarcophagusStates.Exists,
            archaeologist: archaeologist,
            archaeologistPublicKey: arch.currentPublicKey,
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
            sarc.archaeologistPublicKey,
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
        bytes memory newPublicKey,
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
        Utils.signatureCheck(abi.encodePacked(newPublicKey, assetId), v, r, s, sarc.archaeologist);
        
        require(!data.archaeologistUsedKeys[sarc.archaeologistPublicKey], "public key already used");
        data.archaeologistUsedKeys[sarc.archaeologistPublicKey] = true;

        sarc.assetId = assetId;

        Types.Archaeologist storage arch = data.archaeologists[sarc.archaeologist];
        arch.currentPublicKey = newPublicKey;
        
        sarcoToken.transfer(arch.paymentAddress, sarc.storageFee);
        sarc.storageFee = 0;

        emit Events.UpdateSarcophagus(assetDoubleHash, assetId);
        emit Events.UpdateArchaeologistPublicKey(arch.archaeologist, arch.currentPublicKey);

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

        Types.Archaeologist memory arch = data.archaeologists[sarc.archaeologist];

        sarcoToken.transfer(sarc.embalmer, sarc.bounty.add(sarc.storageFee));
        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee); // why do we do digging fee, not storage fee?

        Archaeologists.freeUpBond(data, sarc.archaeologist, sarc.currentCursedBond);
        wipeSarcophagusMoney(sarc);

        data.archaeologistCancels[sarc.archaeologist].push(assetDoubleHash);

        // TODO: update cursed bond calculation ? maybe
        // TODO: update sarcophagus state, maybe need to update "analytics" data

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

        Types.Archaeologist storage arch = data.archaeologists[sarc.archaeologist];

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

        // TODO: do we need to adjust sarco token transferfrom here?
        if (cursedBondAmount > sarc.currentCursedBond) {
            uint256 diff = cursedBondAmount.sub(sarc.currentCursedBond);
            Archaeologists.lockUpBond(data, sarc.archaeologist, diff);
        } else if (cursedBondAmount < sarc.currentCursedBond) {
            uint256 diff = sarc.currentCursedBond.sub(cursedBondAmount);
            Archaeologists.freeUpBond(data, sarc.archaeologist, diff);
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

        Types.Archaeologist storage arch = data.archaeologists[sarc.archaeologist];

        sarcoToken.transfer(
            arch.paymentAddress,
            sarc.diggingFee.add(sarc.bounty)
        );

        Archaeologists.freeUpBond(data, sarc.archaeologist, sarc.currentCursedBond);
        wipeSarcophagusMoney(sarc);

        sarc.state = Types.SarcophagusStates.Done;

        data.archaeologistSuccesses[sarc.archaeologist].push(assetDoubleHash);

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

        (uint256 halfToSender, uint256 halfToEmbalmer) = splitSendDone(
            data,
            sarc.archaeologist,
            paymentAddress,
            sarc,
            sarcoToken
        );

        data.archaeologistAccusals[sarc.archaeologist].push(assetDoubleHash);

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

        Types.Archaeologist storage arch = data.archaeologists[sarc.archaeologist];

        Archaeologists.freeUpBond(data, sarc.archaeologist, sarc.currentCursedBond);

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

        (uint256 halfToSender, uint256 halfToEmbalmer) = splitSendDone(
            data,
            sarc.archaeologist,
            paymentAddress,
            sarc,
            sarcoToken
        );

        data.archaeologistCleanups[sarc.archaeologist].push(assetDoubleHash);

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
