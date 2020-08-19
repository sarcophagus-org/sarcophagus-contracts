// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SarcophagusManager {
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

    event CreateSarcophagus(
        bytes archaeologist,
        address embalmer,
        string name,
        string assetId,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 assetDoubleHash,
        bytes recipientPublicKey
    );

    event RewrapSarcophagus(
        string assetId,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 diggingFee,
        uint256 bounty,
        uint256 cursedBond
    );

    event UnwrapSarcophagus(string assetId, bytes singleHash);

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

    enum SarcophagusStates {DoesNotExist, Exists, Resurrected, Buried}

    struct Sarcophagus {
        SarcophagusStates state;
        bytes archaeologist;
        address embalmer;
        string name;
        uint256 resurrectionTime;
        uint256 resurrectionWindow;
        uint256 diggingFee;
        uint256 bounty;
        bytes32 assetDoubleHash;
        bytes recipientPublicKey;
        uint256 currentCursedBond;
    }

    IERC20 public sarcoToken;

    mapping(address => Archaeologist) public archaeologists;
    address[] public archaeologistAddresses;

    mapping(string => Sarcophagus) public sarcophaguses;

    uint16 minimumResurrectionWindow = 30 minutes;

    constructor(address _sarcoToken) public {
        sarcoToken = IERC20(_sarcoToken);
        emit Creation(_sarcoToken);
    }

    modifier archaeologistExists {
        require(
            archaeologists[msg.sender].exists == true,
            "archaeologist has not been registered yet"
        );
        _;
    }

    function archaeologistCount() public view returns (uint256) {
        return archaeologistAddresses.length;
    }

    function addressFromPublicKey(bytes memory publicKey)
        private
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(publicKey))));
    }

    function registerArchaeologist(
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

        address msgSender = addressFromPublicKey(publicKey);
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

    function updateArchaeologist(
        address paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public archaeologistExists returns (bool) {
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

    function withdrawalBond(uint256 amount)
        public
        archaeologistExists
        returns (bool)
    {
        Archaeologist storage arch = archaeologists[msg.sender];

        arch.freeBond = arch.freeBond.sub(
            amount,
            "requested withdrawal amount is greater than free bond"
        );
        sarcoToken.transfer(arch.paymentAddress, amount);

        emit WithdrawalFreeBond(arch.publicKey, amount);

        return true;
    }

    function createSarcophagus(
        string memory name,
        bytes memory archaeologistPublicKey,
        string memory assetId,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 assetDoubleHash,
        bytes memory recipientPublicKey
    ) public returns (bool) {
        address archAddress = addressFromPublicKey(archaeologistPublicKey);
        Archaeologist storage arch = archaeologists[archAddress];

        require(
            sarcophaguses[assetId].state == SarcophagusStates.DoesNotExist,
            "sarcophagus already exists"
        );
        require(arch.exists == true, "archaeologist does not exist");
        require(
            resurrectionTime > block.timestamp,
            "resurrection time must be in the future"
        );
        require(
            resurrectionTime <= block.timestamp + arch.maximumResurrectionTime,
            "resurrection time too far in the future"
        );
        require(diggingFee >= arch.minimumDiggingFee, "digging fee is too low");
        require(bounty >= arch.minimumBounty, "bounty is too low");
        require(
            recipientPublicKey.length == 64,
            "recipient public key must be 64 bytes"
        );

        sarcoToken.transferFrom(
            msg.sender,
            address(this),
            diggingFee.add(bounty)
        );

        uint256 gracePeriod = (resurrectionTime.sub(block.timestamp)).div(100);
        if (gracePeriod < minimumResurrectionWindow) {
            gracePeriod = minimumResurrectionWindow;
        }

        // TODO: implment an algorithm to figure this out
        uint256 cursedBondAmount = diggingFee.add(bounty);

        arch.freeBond = arch.freeBond.sub(
            cursedBondAmount,
            "archaeologist does not have enough free bond"
        );
        arch.cursedBond = arch.cursedBond.add(cursedBondAmount);

        Sarcophagus memory sarcophagus = Sarcophagus(
            SarcophagusStates.Exists,
            archaeologistPublicKey,
            msg.sender,
            name,
            resurrectionTime,
            gracePeriod,
            diggingFee,
            bounty,
            assetDoubleHash,
            recipientPublicKey,
            cursedBondAmount
        );

        sarcophaguses[assetId] = sarcophagus;

        emit CreateSarcophagus(
            sarcophagus.archaeologist,
            sarcophagus.embalmer,
            sarcophagus.name,
            assetId,
            sarcophagus.resurrectionTime,
            sarcophagus.resurrectionWindow,
            sarcophagus.diggingFee,
            sarcophagus.bounty,
            sarcophagus.assetDoubleHash,
            sarcophagus.recipientPublicKey
        );

        return true;
    }

    function rewrapSarcophagus(
        string memory assetId,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty
    ) public returns (bool) {
        Sarcophagus storage sarc = sarcophaguses[assetId];
        address archAddress = addressFromPublicKey(sarc.archaeologist);
        Archaeologist memory arch = archaeologists[archAddress];

        require(
            sarc.state != SarcophagusStates.DoesNotExist,
            "sarcophagus does not exist"
        );
        require(
            sarc.state != SarcophagusStates.Resurrected,
            "sarcophagus has already been resurrected"
        );
        require(
            sarc.state != SarcophagusStates.Buried,
            "sarcophagus has already been buried"
        );

        require(sarc.embalmer == msg.sender, "not your sarcophagus to rewrap");
        require(
            sarc.resurrectionTime >= block.timestamp,
            "sarcophagus rewrapping time has expired"
        );
        require(
            resurrectionTime > block.timestamp,
            "resurrection time must be in the future"
        );
        require(
            resurrectionTime <= block.timestamp + arch.maximumResurrectionTime,
            "resurrection time too far in the future"
        );
        require(diggingFee >= arch.minimumDiggingFee, "digging fee is too low");
        require(bounty >= arch.minimumBounty, "bounty is too low");

        sarcoToken.transfer(archAddress, sarc.diggingFee);

        // TODO: implment an algorithm to figure this out
        uint256 cursedBondAmount = diggingFee.add(bounty);

        if (cursedBondAmount > sarc.currentCursedBond) {
            uint256 difference = cursedBondAmount.sub(sarc.currentCursedBond);

            arch.freeBond = arch.freeBond.sub(
                difference,
                "archaeologist does not have enough free bond"
            );
            arch.cursedBond = arch.cursedBond.add(difference);
        } else if (cursedBondAmount < sarc.currentCursedBond) {
            uint256 difference = sarc.currentCursedBond.sub(cursedBondAmount);

            arch.freeBond = arch.freeBond.add(difference);
            arch.cursedBond = arch.cursedBond.sub(cursedBondAmount);
        }

        uint256 gracePeriod = (resurrectionTime.sub(block.timestamp)).div(100);
        if (gracePeriod < minimumResurrectionWindow) {
            gracePeriod = minimumResurrectionWindow;
        }

        sarc.resurrectionTime = resurrectionTime;
        sarc.diggingFee = diggingFee;
        sarc.bounty = bounty;
        sarc.currentCursedBond = cursedBondAmount;
        sarc.resurrectionWindow = gracePeriod;

        emit RewrapSarcophagus(
            assetId,
            resurrectionTime,
            gracePeriod,
            diggingFee,
            bounty,
            cursedBondAmount
        );

        return true;
    }

    function unwrapSarcophagus(string memory assetId, bytes memory singleHash)
        public
        returns (bool)
    {
        Sarcophagus storage sarc = sarcophaguses[assetId];
        address archAddress = addressFromPublicKey(sarc.archaeologist);
        Archaeologist storage arch = archaeologists[archAddress];

        require(
            sarc.state != SarcophagusStates.DoesNotExist,
            "sarcophagus does not exist"
        );
        require(
            sarc.state != SarcophagusStates.Resurrected,
            "sarcophagus has already been resurrected"
        );
        require(
            sarc.state != SarcophagusStates.Buried,
            "sarcophagus has already been buried"
        );
        require(
            sarc.resurrectionTime < block.timestamp,
            "it's not time to unwrap the sarcophagus"
        );
        require(
            sarc.resurrectionTime.add(sarc.resurrectionWindow) >=
                block.timestamp,
            "the resurrection window has expired"
        );
        require(
            sarc.assetDoubleHash == keccak256(singleHash),
            "input hash does not match sarcophagus hash"
        );

        sarcoToken.transfer(archAddress, sarc.diggingFee.add(sarc.bounty));

        arch.freeBond = arch.freeBond.add(sarc.currentCursedBond);
        arch.cursedBond = arch.cursedBond.sub(sarc.currentCursedBond);

        sarc.state = SarcophagusStates.Resurrected;

        // TODO: update cursed bond calculation

        emit UnwrapSarcophagus(assetId, singleHash);

        return true;
    }
}
