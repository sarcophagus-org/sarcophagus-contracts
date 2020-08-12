// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./math/SafeMath.sol";
import "./token/ERC20/IERC20.sol";

contract Sarcophagus {
    using SafeMath for uint256;

    event Creation(address sarcophagusContract);

    event RegisterArchaeologist(
        bytes publicKey,
        address paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 bond
    );

    event UpdateArchaeologist(
        bytes publicKey,
        address paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 addedBond
    );

    event WithdrawalFreeBond(bytes publicKey, uint256 withdrawnBond);

    struct Archaeologist {
        bool exists;
        bytes publicKey;
        address paymentAddress;
        uint256 minimumBounty;
        uint256 minimumDiggingFee;
        uint256 maximumResurrectionTime;
        uint256 freeBond;
        uint256 cursedBond;
    }

    IERC20 public sarcoToken;
    mapping(address => Archaeologist) public archaeologists;
    address[] public archaeologistAddresses;

    constructor(address _sarcoToken) public {
        sarcoToken = IERC20(_sarcoToken);
        emit Creation(_sarcoToken);
    }

    function archaeologistCount() public view returns (uint256) {
        return archaeologistAddresses.length;
    }

    function register(
        bytes memory publicKey,
        address paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public returns (bool) {
        require(
            archaeologists[msg.sender].exists == false,
            "archaeologist already registered"
        );

        require(publicKey.length == 64, "public key must be 64 bytes");

        address msgSender = address(uint160(uint256(keccak256(publicKey))));
        require(
            msgSender == msg.sender,
            "transaction address must have been derived from public key input"
        );

        sarcoToken.transferFrom(msg.sender, address(this), freeBond);

        Archaeologist memory newArch = Archaeologist(
            true,
            publicKey,
            paymentAddress,
            minimumBounty,
            minimumDiggingFee,
            maximumResurrectionTime,
            freeBond,
            0
        );

        archaeologists[msg.sender] = newArch;
        archaeologistAddresses.push(msg.sender);

        emit RegisterArchaeologist(
            newArch.publicKey,
            newArch.paymentAddress,
            newArch.minimumBounty,
            newArch.minimumDiggingFee,
            newArch.maximumResurrectionTime,
            newArch.freeBond
        );

        return true;
    }

    modifier exists {
        require(
            archaeologists[msg.sender].exists == true,
            "archaeologist has not been registered yet"
        );
        _;
    }

    function update(
        address paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public exists returns (bool) {
        Archaeologist storage arch = archaeologists[msg.sender];
        arch.paymentAddress = paymentAddress;
        arch.minimumBounty = minimumBounty;
        arch.minimumDiggingFee = minimumDiggingFee;
        arch.maximumResurrectionTime = maximumResurrectionTime;
        arch.freeBond = arch.freeBond.add(freeBond);

        if (freeBond > 0) {
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        emit UpdateArchaeologist(
            arch.publicKey,
            arch.paymentAddress,
            arch.minimumBounty,
            arch.minimumDiggingFee,
            arch.maximumResurrectionTime,
            freeBond
        );

        return true;
    }

    function withdrawalBond(uint256 amount) public exists returns (bool) {
        Archaeologist storage arch = archaeologists[msg.sender];

        arch.freeBond = arch.freeBond.sub(
            amount,
            "requested withdrawal amount is greater than free bond"
        );
        sarcoToken.transfer(arch.paymentAddress, amount);

        emit WithdrawalFreeBond(arch.publicKey, amount);

        return true;
    }
}
