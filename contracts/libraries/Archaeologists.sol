// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Utils.sol";
import "./Events.sol";
import "./Types.sol";
import "./Datas.sol";

/**
 * @title A library implementing Archaeologist-specific logic in the
 * Sarcophagus system
 * @notice This library includes public functions for manipulating
 * archaeologists in the Sarcophagus system
 */
library Archaeologists {
    /**
     * @notice Checks that an archaeologist exists, or doesn't exist, and
     * and reverts if necessary
     * @param data the system's data struct instance
     * @param account the archaeologist address to check existence of
     * @param exists bool which flips whether function reverts if archaeologist
     * exists or not
     */
    function archaeologistExists(
        Datas.Data storage data,
        address account,
        bool exists
    ) public view {
        // set the error message
        string memory err = "archaeologist has not been registered yet";
        if (!exists) err = "archaeologist has already been registered";

        // revert if necessary
        require(data.archaeologists[account].exists == exists, err);
    }

    /**
     * @notice Increases internal data structure which tracks free bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase free bond by
     */
    function increaseFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // increase the freeBond variable by amount
        arch.freeBond = arch.freeBond + amount;
    }

    /**
     * @notice Decreases internal data structure which tracks free bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease free bond by
     */
    function decreaseFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // decrease the free bond variable by amount, reverting if necessary
        require(
            arch.freeBond >= amount,
            "archaeologist does not have enough free bond"
        );
        arch.freeBond = arch.freeBond - amount;
    }

    /**
     * @notice Increases internal data structure which tracks cursed bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase cursed bond by
     */
    function increaseCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // increase the freeBond variable by amount
        arch.cursedBond = arch.cursedBond + amount;
    }

    /**
     * @notice Decreases internal data structure which tracks cursed bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease cursed bond by
     */
    function decreaseCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // decrease the free bond variable by amount
        arch.cursedBond = arch.cursedBond - amount;
    }

    /**
     * @notice Given an archaeologist and amount, decrease free bond and
     * increase cursed bond
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease free bond and increase cursed bond
     */
    function lockUpBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        decreaseFreeBond(data, archAddress, amount);
        increaseCursedBond(data, archAddress, amount);
    }

    /**
     * @notice Given an archaeologist and amount, increase free bond and
     * decrease cursed bond
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase free bond and decrease cursed bond
     */
    function freeUpBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        increaseFreeBond(data, archAddress, amount);
        decreaseCursedBond(data, archAddress, amount);
    }

    /**
     * @notice Calculates and returns the curse for any sarcophagus
     * @param diggingFee the digging fee of a sarcophagus
     * @param bounty the bounty of a sarcophagus
     * @return amount of the curse
     * @dev Current implementation simply adds the two inputs together. Future
     * strategies should use historical data to build a curve to change this
     * amount over time.
     */
    function getCursedBond(uint256 diggingFee, uint256 bounty)
        public
        pure
        returns (uint256)
    {
        // TODO: implment a better algorithm, using some concept of past state
        return diggingFee + bounty;
    }

    /**
     * @notice Registers a new archaeologist in the system
     * @param data the system's data struct instance
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
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to start with
     * @param sarcoToken the SARCO token used for payment handling
     * @return index of the new archaeologist
     */
    function registerArchaeologist(
        Datas.Data storage data,
        bytes memory currentPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (uint256) {
        // verify that the archaeologist does not already exist
        archaeologistExists(data, msg.sender, false);

        // verify that the public key length is accurate
        Utils.publicKeyLength(currentPublicKey);

        // transfer SARCO tokens from the archaeologist to this contract, to be
        // used as their free bond. can be 0, which indicates that the
        // archaeologist is not eligible for any new jobs
        if (freeBond > 0) {
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        // create a new archaeologist
        Types.Archaeologist memory newArch =
            Types.Archaeologist({
                exists: true,
                currentPublicKey: currentPublicKey,
                endpoint: endpoint,
                paymentAddress: paymentAddress,
                feePerByte: feePerByte,
                minimumBounty: minimumBounty,
                minimumDiggingFee: minimumDiggingFee,
                maximumResurrectionTime: maximumResurrectionTime,
                freeBond: freeBond,
                cursedBond: 0
            });

        // save the new archaeologist into relevant data structures
        data.archaeologists[msg.sender] = newArch;
        data.archaeologistAddresses.push(msg.sender);

        // emit an event
        emit Events.RegisterArchaeologist(
            msg.sender,
            newArch.currentPublicKey,
            newArch.endpoint,
            newArch.paymentAddress,
            newArch.feePerByte,
            newArch.minimumBounty,
            newArch.minimumDiggingFee,
            newArch.maximumResurrectionTime,
            newArch.freeBond
        );

        // return index of the new archaeologist
        return data.archaeologistAddresses.length - 1;
    }

    /**
     * @notice An archaeologist may update their profile
     * @param data the system's data struct instance
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
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to add to their profile
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the update was successful
     */
    function updateArchaeologist(
        Datas.Data storage data,
        bytes memory newPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (bool) {
        // verify that the archaeologist exists, and is the sender of this
        // transaction
        archaeologistExists(data, msg.sender, true);

        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[msg.sender];

        // if archaeologist is updating their active public key, emit an event
        if (keccak256(arch.currentPublicKey) != keccak256(newPublicKey)) {
            emit Events.UpdateArchaeologistPublicKey(msg.sender, newPublicKey);
            arch.currentPublicKey = newPublicKey;
        }

        // update the rest of the archaeologist profile
        arch.endpoint = endpoint;
        arch.paymentAddress = paymentAddress;
        arch.feePerByte = feePerByte;
        arch.minimumBounty = minimumBounty;
        arch.minimumDiggingFee = minimumDiggingFee;
        arch.maximumResurrectionTime = maximumResurrectionTime;

        // the freeBond variable acts as an incrementer, so only if it's above
        // zero will we update their profile variable and transfer the tokens
        if (freeBond > 0) {
            increaseFreeBond(data, msg.sender, freeBond);
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        // emit an event
        emit Events.UpdateArchaeologist(
            msg.sender,
            arch.endpoint,
            arch.paymentAddress,
            arch.feePerByte,
            arch.minimumBounty,
            arch.minimumDiggingFee,
            arch.maximumResurrectionTime,
            freeBond
        );

        // return true
        return true;
    }

    /**
     * @notice Archaeologist can withdraw any of their free bond
     * @param data the system's data struct instance
     * @param amount the amount of the archaeologist's free bond that they're
     * withdrawing
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the withdrawal was successful
     */
    function withdrawBond(
        Datas.Data storage data,
        uint256 amount,
        IERC20 sarcoToken
    ) public returns (bool) {
        // verify that the archaeologist exists, and is the sender of this
        // transaction
        archaeologistExists(data, msg.sender, true);

        // move free bond out of the archaeologist
        decreaseFreeBond(data, msg.sender, amount);

        // transfer the freed SARCOs back to the archaeologist
        sarcoToken.transfer(msg.sender, amount);

        // emit event
        emit Events.WithdrawalFreeBond(msg.sender, amount);

        // return true
        return true;
    }
}
