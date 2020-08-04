// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract Sarcophagus {

  event RegisterArchaeologist(
    bytes publicKey,
    address paymentAddress,
    uint minimumBounty,
    uint minimumDiggingFee,
    uint maximumResurrectionTime,
    uint bond
  );

  struct Archaeologist {
    address paymentAddress;
    uint minimumBounty;
    uint minimumDiggingFee;
    uint maximumResurrectionTime;
    uint bond;
  }

  mapping(bytes => Archaeologist) public archaeologists;
  bytes[] public archaeologistKeys;

  function archaeologistCount() public view returns (uint) {
    return archaeologistKeys.length;
  }

  function register(
    bytes memory publicKey,
    uint minimumBounty,
    uint minimumDiggingFee,
    uint maximumResurrectionTime
  ) public payable returns (bool) {
    require(archaeologists[publicKey].paymentAddress == address(0), "archaeologist already registered");
    require(publicKey.length == 64, "public key must be 64 bytes");

    Archaeologist memory newArch = Archaeologist(
      msg.sender,
      minimumBounty,
      minimumDiggingFee,
      maximumResurrectionTime,
      msg.value
    );

    archaeologists[publicKey] = newArch;
    archaeologistKeys.push(publicKey);

    emit RegisterArchaeologist(
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
