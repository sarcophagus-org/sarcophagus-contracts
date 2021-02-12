// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility functions used within the Sarcophagus system
 * @notice This library implements various functions that are used throughout
 * Sarcophagus, mainly to DRY up the codebase
 * @dev these functions are all stateless, public, pure/view
 */
library Utils {
    /**
     * @notice Reverts if the public key length is not exactly 64 bytes long
     * @param publicKey the key to check length of
     */
    function publicKeyLength(bytes memory publicKey) public pure {
        require(publicKey.length == 64, "public key must be 64 bytes");
    }

    /**
     * @notice Reverts if the hash of singleHash does not equal doubleHash
     * @param doubleHash the hash to compare hash of singleHash to
     * @param singleHash the value to hash and compare against doubleHash
     */
    function hashCheck(bytes32 doubleHash, bytes memory singleHash)
        public
        pure
    {
        require(doubleHash == keccak256(singleHash), "hashes do not match");
    }

    /**
     * @notice Reverts if the input string is not empty
     * @param assetId the string to check
     */
    function confirmAssetIdNotSet(string memory assetId) public pure {
        require(bytes(assetId).length == 0, "assetId has already been set");
    }

    /**
     * @notice Reverts if existing assetId is not empty, or if new assetId is
     * @param existingAssetId the orignal assetId to check, make sure is empty
     * @param newAssetId the new assetId, which must not be empty
     */
    function assetIdsCheck(
        string memory existingAssetId,
        string memory newAssetId
    ) public pure {
        // verify that the existingAssetId is currently empty
        confirmAssetIdNotSet(existingAssetId);

        require(bytes(newAssetId).length > 0, "assetId must not have 0 length");
    }

    /**
     * @notice Reverts if the given data and signature did not come from the
     * given address
     * @param data the payload which has been signed
     * @param v signature element
     * @param r signature element
     * @param s signature element
     * @param account address to confirm data and signature came from
     */
    function signatureCheck(
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address account
    ) public pure {
        // generate the address for a given data and signature
        address hopefulAddress = ecrecover(keccak256(data), v, r, s);

        require(
            hopefulAddress == account,
            "signature did not come from correct account"
        );
    }

    /**
     * @notice Reverts if the given resurrection time is not in the future
     * @param resurrectionTime the time to check against block.timestamp
     */
    function resurrectionInFuture(uint256 resurrectionTime) public view {
        require(
            resurrectionTime > block.timestamp,
            "resurrection time must be in the future"
        );
    }

    /**
     * @notice Calculates the grace period that an archaeologist has after a
     * sarcophagus has reached its resurrection time
     * @param resurrectionTime the resurrection timestamp of a sarcophagus
     * @return the grace period
     * @dev The grace period is dependent on how far out the resurrection time
     * is. The longer out the resurrection time, the longer the grace period.
     * There is a minimum grace period of 30 minutes, otherwise, it's
     * calculated as 1% of the time between now and resurrection time.
     */
    function getGracePeriod(uint256 resurrectionTime)
        public
        view
        returns (uint256)
    {
        // set a minimum window of 30 minutes
        uint16 minimumResurrectionWindow = 30 minutes;

        // calculate 1% of the relative time between now and the resurrection
        // time
        uint256 gracePeriod = (resurrectionTime - block.timestamp) / 100;

        // if our calculated grace period is less than the minimum time, we'll
        // use the minimum time instead
        if (gracePeriod < minimumResurrectionWindow) {
            gracePeriod = minimumResurrectionWindow;
        }

        // return that grace period
        return gracePeriod;
    }

    /**
     * @notice Reverts if we're not within the resurrection window (on either
     * side)
     * @param resurrectionTime the resurrection time of the sarcophagus
     * (absolute, i.e. a date time stamp)
     * @param resurrectionWindow the resurrection window of the sarcophagus
     * (relative, i.e. "30 minutes")
     */
    function unwrapTime(uint256 resurrectionTime, uint256 resurrectionWindow)
        public
        view
    {
        // revert if too early
        require(
            resurrectionTime <= block.timestamp,
            "it's not time to unwrap the sarcophagus"
        );

        // revert if too late
        require(
            resurrectionTime + resurrectionWindow >= block.timestamp,
            "the resurrection window has expired"
        );
    }

    /**
     * @notice Reverts if msg.sender is not equal to passed-in address
     * @param account the account to verify is msg.sender
     */
    function sarcophagusUpdater(address account) public view {
        require(
            account == msg.sender,
            "sarcophagus cannot be updated by account"
        );
    }

    /**
     * @notice Reverts if the input resurrection time, digging fee, or bounty
     * don't fit within the other given maximum and minimum values
     * @param resurrectionTime the resurrection time to check
     * @param diggingFee the digging fee to check
     * @param bounty the bounty to check
     * @param maximumResurrectionTime the maximum resurrection time to check
     * against, in relative terms (i.e. "1 year" is 31536000 (seconds))
     * @param minimumDiggingFee the minimum digging fee to check against
     * @param minimumBounty the minimum bounty to check against
     */
    function withinArchaeologistLimits(
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty,
        uint256 maximumResurrectionTime,
        uint256 minimumDiggingFee,
        uint256 minimumBounty
    ) public view {
        // revert if the given resurrection time is too far in the future
        require(
            resurrectionTime <= block.timestamp + maximumResurrectionTime,
            "resurrection time too far in the future"
        );

        // revert if the given digging fee is too low
        require(diggingFee >= minimumDiggingFee, "digging fee is too low");

        // revert if the given bounty is too low
        require(bounty >= minimumBounty, "bounty is too low");
    }
}
