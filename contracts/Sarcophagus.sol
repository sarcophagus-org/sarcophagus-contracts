// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/Events.sol";
import "./libraries/Types.sol";
import "./libraries/Datas.sol";
import "./libraries/Archaeologists.sol";
import "./libraries/Sarcophaguses.sol";

/**
 * @title The main Sarcophagus system contract
 * @notice This contract implements the entire public interface for the
 * Sarcophagus system
 *
 * Sarcophagus implements a Dead Man's Switch using the Ethereum network as
 * the official source of truth for the switch (the "sarcophagus"), the Arweave
 * blockchain as the data storage layer for the encrypted payload, and a
 * decentralized network of secret-holders (the "archaeologists") who are
 * responsible for keeping a private key secret until the dead man's switch is
 * activated (via inaction by the "embalmer", the creator of the sarcophagus).
 *
 * @dev All function calls "proxy" down to functions implemented in one of
 * many libraries
 */
contract Sarcophagus {
    using SafeMath for uint256;

    // keep a reference to the SARCO token, which is used for payments
    // throughout the system
    IERC20 public sarcoToken;

    // all system data is stored within this single instance (_data) of the
    // Data struct
    Datas.Data private _data;

    /**
     * @notice Contract constructor
     * @param _sarcoToken The address of the SARCO token
     */
    constructor(address _sarcoToken) public {
        sarcoToken = IERC20(_sarcoToken);
        emit Events.Creation(_sarcoToken);
    }

    /**
     * @notice Return the number of archaeologists that have been registered
     * @return total registered archaeologist count
     */
    function archaeologistCount() public view returns (uint256) {
        return _data.archaeologistAddresses.length;
    }

    /**
     * @notice Given an index (of the full archaeologist array), return the
     * archaeologist address at that index
     * @param index The index of the registered archaeologist
     * @return address of the archaeologist
     */
    function archaeologistAddresses(uint256 index)
        public
        view
        returns (address)
    {
        return _data.archaeologistAddresses[index];
    }

    /**
     * @notice Given an archaeologist address, return that archaeologist's
     * profile
     * @param account The archaeologist account's address
     * @return exists if the given archaeologist address is registered
     * @return currentPublicKey the public key which should be used for the
     * next created sarcophagus, for this archaeologist
     * @return endpoint where to contact this archaeologist on the internet
     * @return paymentAddress all collected payments for the archaeologist
     * will be sent here
     * @return feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @return minimumBounty the minimum bounty for a sarcophagus that the
     * given archaeologist will accept
     * @return minimumDiggingFee the minimum digging fee for a sarcophagus
     * that the given archaeologist will accept
     * @return maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the given archaeologist will accept
     * @return freeBond the amount of SARCO bond that is available (to be
     * cursed) for the given archaeologist
     * @return cursedBond the amount of SARCO which is currenly bonded in
     * existing sarcophagi
     */
    function archaeologists(address account)
        public
        view
        returns (
            bool exists,
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
        Types.Archaeologist memory arch = _data.archaeologists[account];
        return (
            arch.exists,
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

    /**
     * @notice Return the total number of sarcophagi that have been created
     * @return the number of sarcophagi that have ever been created
     */
    function sarcophagusCount() public view returns (uint256) {
        return _data.sarcophagusIdentifiers.length;
    }

    /**
     * @notice Return the unique identifier of a sarcophagus, given it's index
     * @param index The index of the sarcophagus
     * @return the unique identifier of the given sarcophagus
     */
    function sarcophagusIdentifier(uint256 index)
        public
        view
        returns (bytes32)
    {
        return _data.sarcophagusIdentifiers[index];
    }

    /**
     * @notice Returns the count of sarcophagi created by a specific embalmer
     * @param embalmer The address of the given embalmer
     * @return the number of sarcophagi which have been created by an embalmer
     */
    function embalmerSarcophagusCount(address embalmer)
        public
        view
        returns (uint256)
    {
        return _data.embalmerSarcophaguses[embalmer].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given embalmer
     * and index
     * @param embalmer The address of an embalmer
     * @param index The index of the embalmer's list of sarcophagi
     * @return the double hash associated with the index of the embalmer's
     * sarcophagi
     */
    function embalmerSarcophagusIdentifier(address embalmer, uint256 index)
        public
        view
        returns (bytes32)
    {
        return _data.embalmerSarcophaguses[embalmer][index];
    }

    /**
     * @notice Returns the count of sarcophagi created for a specific
     * archaeologist
     * @param archaeologist The address of the given archaeologist
     * @return the number of sarcophagi which have been created for an
     * archaeologist
     */
    function archaeologistSarcophagusCount(address archaeologist)
        public
        view
        returns (uint256)
    {
        return _data.embalmerSarcophaguses[archaeologist].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given
     * archaeologist and index
     * @param archaeologist The address of an archaeologist
     * @param index The index of the archaeologist's list of sarcophagi
     * @return the identifier associated with the index of the archaeologist's
     * sarcophagi
     */
    function archaeologistSarcophagusIdentifier(
        address archaeologist,
        uint256 index
    ) public view returns (bytes32) {
        return _data.archaeologistSarcophaguses[archaeologist][index];
    }

    /**
     * @notice Returns the count of sarcophagi created for a specific recipient
     * @param recipient The address of the given recipient
     * @return the number of sarcophagi which have been created for a recipient
     */
    function recipientSarcophagusCount(address recipient)
        public
        view
        returns (uint256)
    {
        return _data.recipientSarcophaguses[recipient].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given recipient
     * and index
     * @param recipient The address of a recipient
     * @param index The index of the recipient's list of sarcophagi
     * @return the identifier associated with the index of the recipient's
     * sarcophagi
     */
    function recipientSarcophagusIdentifier(address recipient, uint256 index)
        public
        view
        returns (bytes32)
    {
        return _data.recipientSarcophaguses[recipient][index];
    }

    /**
     * @notice Returns sarcophagus data given an indentifier
     * @param identifier the unique identifier a sarcophagus
     * @return state of the sarcophagus
     * @return archaeologist assigned to the sarcopahgus
     * @return embalmer who created the sarcophagus
     * @return archaeologistPublicKey the public key that the archaeologist
     * used to encrypt this sarcophgagus
     * @return resurrectionTime the time by which the sarcophagus needs to be
     * rewrapped before it can be unwraped
     * @return resurrectionWindow the time window after resurrection time
     * during which the archaeologist can unwrap the sarcophagus
     * @return name of the sarcopahgus
     * @return assetId the Arweave identifier of the sarcophagus
     * @return storageFee the storage fee collected by the archaeologist
     */
    function sarcophagus(bytes32 identifier)
        public
        view
        returns (
            Types.SarcophagusStates state,
            address archaeologist,
            address embalmer,
            bytes memory archaeologistPublicKey,
            uint256 resurrectionTime,
            uint256 resurrectionWindow,
            string memory name,
            string memory assetId,
            uint256 storageFee
        )
    {
        Types.Sarcophagus memory sarc = _data.sarcophaguses[identifier];
        return (
            sarc.state,
            sarc.archaeologist,
            sarc.embalmer,
            sarc.archaeologistPublicKey,
            sarc.resurrectionTime,
            sarc.resurrectionWindow,
            sarc.name,
            sarc.assetId,
            sarc.storageFee
        );
    }

    /**
     * @notice Registers a new archaeologist in the system
     * @param currentPublicKey the public key to be used in the first
     * sarcophagus
     * @param endpoint where to contact this archaeologist on the internet
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to start with
     * @return bool indicating that the registration was successful
     */
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
                _data,
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

    /**
     * @notice An archaeologist may update their profile
     * @param endpoint where to contact this archaeologist on the internet
     * @param newPublicKey the public key to be used in the next
     * sarcophagus
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to add to their profile
     * @return bool indicating that the update was successful
     */
    function updateArchaeologist(
        string memory endpoint,
        bytes memory newPublicKey,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public returns (bool) {
        return
            Archaeologists.updateArchaeologist(
                _data,
                newPublicKey,
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

    /**
     * @notice Archaeologist can withdraw any of their free bond
     * @param amount the amount of the archaeologist's free bond that they're
     * withdrawing
     * @return bool indicating that the withdrawal was successful
     */
    function withdrawBond(uint256 amount) public returns (bool) {
        return Archaeologists.withdrawBond(_data, amount, sarcoToken);
    }

    /**
     * @notice Embalmer creates the skeleton for a new sarcopahgus
     * @param name the name of the sarcophagus
     * @param archaeologist the address of a registered archaeologist to
     * assign this sarcophagus to
     * @param resurrectionTime the resurrection time of the sarcophagus
     * @param storageFee the storage fee that the archaeologist will receive,
     * for saving this sarcophagus on Arweave
     * @param diggingFee the digging fee that the archaeologist will receive at
     * the first rewrap
     * @param bounty the bounty that the archaeologist will receive when the
     * sarcophagus is unwrapped
     * @param identifier the identifier of the sarcophagus, which is the hash
     * of the hash of the inner encrypted layer of the sarcophagus
     * @param recipientPublicKey the public key of the recipient
     * @return bool indicating that the creation was successful
     */
    function createSarcophagus(
        string memory name,
        address archaeologist,
        uint256 resurrectionTime,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 identifier,
        bytes memory recipientPublicKey
    ) public returns (bool) {
        return
            Sarcophaguses.createSarcophagus(
                _data,
                name,
                archaeologist,
                resurrectionTime,
                storageFee,
                diggingFee,
                bounty,
                identifier,
                recipientPublicKey,
                sarcoToken
            );
    }

    /**
     * @notice Embalmer updates a sarcophagus given it's identifier, after
     * the archaeologist has uploaded the encrypted payload onto Arweave
     * @param newPublicKey the archaeologist's new public key, to use for
     * encrypting the next sarcophagus that they're assigned to
     * @param identifier the identifier of the sarcophagus
     * @param assetId the identifier of the encrypted asset on Arweave
     * @param v signature element
     * @param r signature element
     * @param s signature element
     * @return bool indicating that the update was successful
     */
    function updateSarcophagus(
        bytes memory newPublicKey,
        bytes32 identifier,
        string memory assetId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        return
            Sarcophaguses.updateSarcophagus(
                _data,
                newPublicKey,
                identifier,
                assetId,
                v,
                r,
                s,
                sarcoToken
            );
    }

    /**
     * @notice An embalmer may cancel a sarcophagus if it hasn't been
     * completely created
     * @param identifier the identifier of the sarcophagus
     * @return bool indicating that the cancel was successful
     */
    function cancelSarcophagus(bytes32 identifier) public returns (bool) {
        return Sarcophaguses.cancelSarcophagus(_data, identifier, sarcoToken);
    }

    /**
     * @notice Embalmer can extend the resurrection time of the sarcophagus,
     * as long as the previous resurrection time is in the future
     * @param identifier the identifier of the sarcophagus
     * @param resurrectionTime new resurrection time for the rewrapped
     * sarcophagus
     * @param diggingFee new digging fee for the rewrapped sarcophagus
     * @param bounty new bounty for the rewrapped sarcophagus
     * @return bool indicating that the rewrap was successful
     */
    function rewrapSarcophagus(
        bytes32 identifier,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty
    ) public returns (bool) {
        return
            Sarcophaguses.rewrapSarcophagus(
                _data,
                identifier,
                resurrectionTime,
                diggingFee,
                bounty,
                sarcoToken
            );
    }

    /**
     * @notice Given a sarcophagus identifier, preimage, and private key,
     * verify that the data is valid and close out that sarcophagus
     * @param identifier the identifier of the sarcophagus
     * @param privateKey the archaeologist's private key which will decrypt the
     * outer layer of the encrypted payload on Arweave
     * @return bool indicating that the unwrap was successful
     */
    function unwrapSarcophagus(bytes32 identifier, bytes32 privateKey)
        public
        returns (bool)
    {
        return
            Sarcophaguses.unwrapSarcophagus(
                _data,
                identifier,
                privateKey,
                sarcoToken
            );
    }

    /**
     * @notice Given a sarcophagus, accuse the archaeologist for unwrapping the
     * sarcophagus early
     * @param identifier the identifier of the sarcophagus
     * @param singleHash the preimage of the sarcophagus identifier
     * @param paymentAddress the address to receive payment for accusing the
     * archaeologist
     * @return bool indicating that the accusal was successful
     */
    function accuseArchaeologist(
        bytes32 identifier,
        bytes memory singleHash,
        address paymentAddress
    ) public returns (bool) {
        return
            Sarcophaguses.accuseArchaeologist(
                _data,
                identifier,
                singleHash,
                paymentAddress,
                sarcoToken
            );
    }

    /**
     * @notice Extends a sarcophagus resurrection time into infinity
     * effectively signaling that the sarcophagus is over and should never be
     * resurrected
     * @param identifier the identifier of the sarcophagus
     * @return bool indicating that the bury was successful
     */
    function burySarcophagus(bytes32 identifier) public returns (bool) {
        return Sarcophaguses.burySarcophagus(_data, identifier, sarcoToken);
    }

    /**
     * @notice Clean up a sarcophagus whose resurrection time and window have
     * passed. Callable by anyone.
     * @param identifier the identifier of the sarcophagus
     * @param paymentAddress the address to receive payment for cleaning up the
     * sarcophagus
     * @return bool indicating that the clean up was successful
     */
    function cleanUpSarcophagus(bytes32 identifier, address paymentAddress)
        public
        returns (bool)
    {
        return
            Sarcophaguses.cleanUpSarcophagus(
                _data,
                identifier,
                paymentAddress,
                sarcoToken
            );
    }
}
