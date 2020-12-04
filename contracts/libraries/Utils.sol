// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library Utils {
    using SafeMath for uint256;

    function publicKeyLength(bytes memory publicKey) public pure {
        require(publicKey.length == 64, "public key must be 64 bytes");
    }

    function hashCheck(bytes32 doubleHash, bytes memory singleHash)
        public
        pure
    {
        require(doubleHash == keccak256(singleHash), "hashes do not match");
    }

    function confirmAssetIdNotSet(string memory assetId) public pure {
        require(bytes(assetId).length == 0, "assetId has already been set");
    }

    function assetIdsCheck(
        string memory existingAssetId,
        string memory newAssetId
    ) public pure {
        confirmAssetIdNotSet(existingAssetId);
        require(bytes(newAssetId).length > 0, "assetId must not have 0 length");
    }

    function signatureCheck(
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address archAddress
    ) public pure {
        address hopefullyArchAddress = ecrecover(
            keccak256(data),
            v,
            r,
            s
        );

        require(
            hopefullyArchAddress == archAddress,
            "signature did not come from archaeologist"
        );
    }

    function resurrectionInFuture(uint256 resurrectionTime) public view {
        require(
            resurrectionTime > block.timestamp,
            "resurrection time must be in the future"
        );
    }

    function getGracePeriod(uint256 resurrectionTime)
        public
        view
        returns (uint256)
    {
        uint16 minimumResurrectionWindow = 30 minutes;

        // TODO: why divide by 100?
        uint256 gracePeriod = (resurrectionTime.sub(block.timestamp)).div(100);
        if (gracePeriod < minimumResurrectionWindow) {
            gracePeriod = minimumResurrectionWindow;
        }

        return gracePeriod;
    }

    function unwrapTime(uint256 resurrectionTime, uint256 resurrectionWindow)
        public
        view
    {
        require(
            resurrectionTime <= block.timestamp,
            "it's not time to unwrap the sarcophagus"
        );
        require(
            resurrectionTime.add(resurrectionWindow) >= block.timestamp,
            "the resurrection window has expired"
        );
    }

    function sarcophagusUpdater(address embalmer) public view {
        require(
            embalmer == msg.sender,
            "sarcophagus can only be updated by embalmer"
        );
    }

    function withinArchaeologistLimits(
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty,
        uint256 maximumResurrectionTime,
        uint256 minimumDiggingFee,
        uint256 minimumBounty
    ) public view {
        require(
            resurrectionTime <= block.timestamp.add(maximumResurrectionTime),
            "resurrection time too far in the future"
        );
        require(diggingFee >= minimumDiggingFee, "digging fee is too low");
        require(bounty >= minimumBounty, "bounty is too low");
    }
}
