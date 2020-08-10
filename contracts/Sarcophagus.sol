// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract Sarcophagus {
    event RegisterArchaeologist(
        address user,
        bytes publicKey,
        address paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 bond
    );

    struct Archaeologist {
        bool exists;
        address paymentAddress;
        uint256 minimumBounty;
        uint256 minimumDiggingFee;
        uint256 maximumResurrectionTime;
        uint256 bond;
    }

    mapping(bytes => Archaeologist) public archaeologists;
    bytes[] public archaeologistKeys;

    function addArchaeologist(bytes memory publicKey, Archaeologist memory arch)
        private
        returns (bool)
    {
        archaeologists[publicKey] = arch;
        archaeologistKeys.push(publicKey);
        return true;
    }

    function archaeologistCount() public view returns (uint256) {
        return archaeologistKeys.length;
    }

    function register(
        bytes memory publicKey,
        address paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime
    ) public payable returns (bool) {
        require(
            archaeologists[publicKey].exists == false,
            "archaeologist already registered"
        );

        require(publicKey.length == 64, "public key must be 64 bytes");

        address msgSender = address(uint160(uint256(keccak256(publicKey))));
        require(
            msgSender == msg.sender,
            "transaction address must have been derived from public key input"
        );

        Archaeologist memory newArch = Archaeologist(
            true,
            paymentAddress,
            minimumBounty,
            minimumDiggingFee,
            maximumResurrectionTime,
            msg.value
        );

        addArchaeologist(publicKey, newArch);

        emit RegisterArchaeologist(
            msg.sender,
            publicKey,
            newArch.paymentAddress,
            newArch.minimumBounty,
            newArch.minimumDiggingFee,
            newArch.maximumResurrectionTime,
            newArch.bond
        );

        return true;
    }
}
