// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SarcophagusManager {
    using SafeMath for uint256;

    event Creation(address sarcophagusContract);

    event RegisterArchaeologist(
        bytes publicKey,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 bond
    );

    event UpdateArchaeologist(
        bytes publicKey,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 addedBond
    );

    event WithdrawalFreeBond(bytes publicKey, uint256 withdrawnBond);

    event CreateSarcophagus(
        bytes32 assetDoubleHash,
        bytes archaeologist,
        address embalmer,
        string name,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes recipientPublicKey,
        uint256 cursedBond
    );

    event UpdateSarcophagus(bytes32 assetDoubleHash, string assetId);

    event CancelSarcophagus(bytes32 assetDoubleHash);

    event RewrapSarcophagus(
        string assetId,
        bytes32 assetDoubleHash,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 diggingFee,
        uint256 bounty,
        uint256 cursedBond
    );

    event UnwrapSarcophagus(
        string assetId,
        bytes32 assetDoubleHash,
        bytes singleHash
    );

    struct Archaeologist {
        bool exists;
        bytes publicKey;
        string endpoint;
        address paymentAddress;
        uint256 feePerByte;
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
        string assetId;
        bytes recipientPublicKey;
    }

    struct SarcophagusMoney {
        uint256 storageFee;
        uint256 diggingFee;
        uint256 bounty;
        uint256 currentCursedBond;
    }

    IERC20 public sarcoToken;

    mapping(address => Archaeologist) public archaeologists;
    address[] public archaeologistAddresses;
    mapping(address => bytes32[]) public archaeologistCancels;

    mapping(bytes32 => Sarcophagus) public sarcophaguses;
    mapping(bytes32 => SarcophagusMoney) public sarcophagusMonies;

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
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
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

        Archaeologist memory newArch = Archaeologist({
            exists: true,
            publicKey: publicKey,
            endpoint: endpoint,
            paymentAddress: paymentAddress,
            feePerByte: feePerByte,
            minimumBounty: minimumBounty,
            minimumDiggingFee: minimumDiggingFee,
            maximumResurrectionTime: maximumResurrectionTime,
            freeBond: freeBond,
            cursedBond: 0
        });

        archaeologists[msg.sender] = newArch;
        archaeologistAddresses.push(msg.sender);

        emit RegisterArchaeologist(
            newArch.publicKey,
            newArch.endpoint,
            newArch.paymentAddress,
            newArch.feePerByte,
            newArch.minimumBounty,
            newArch.minimumDiggingFee,
            newArch.maximumResurrectionTime,
            newArch.freeBond
        );

        return true;
    }

    function updateArchaeologist(
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public archaeologistExists returns (bool) {
        Archaeologist storage arch = archaeologists[msg.sender];
        arch.endpoint = endpoint;
        arch.paymentAddress = paymentAddress;
        arch.feePerByte = feePerByte;
        arch.minimumBounty = minimumBounty;
        arch.minimumDiggingFee = minimumDiggingFee;
        arch.maximumResurrectionTime = maximumResurrectionTime;
        arch.freeBond = arch.freeBond.add(freeBond);

        if (freeBond > 0) {
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        emit UpdateArchaeologist(
            arch.publicKey,
            arch.endpoint,
            arch.paymentAddress,
            arch.feePerByte,
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
        uint256 resurrectionTime,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 assetDoubleHash,
        bytes memory recipientPublicKey
    ) public returns (bool) {
        address archAddress = addressFromPublicKey(archaeologistPublicKey);
        Archaeologist storage arch = archaeologists[archAddress];

        require(
            sarcophaguses[assetDoubleHash].state ==
                SarcophagusStates.DoesNotExist,
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
            diggingFee.add(bounty).add(storageFee)
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

        Sarcophagus memory sarcophagus = Sarcophagus({
            state: SarcophagusStates.Exists,
            archaeologist: archaeologistPublicKey,
            embalmer: msg.sender,
            name: name,
            resurrectionTime: resurrectionTime,
            resurrectionWindow: gracePeriod,
            assetId: "",
            recipientPublicKey: recipientPublicKey
        });

        SarcophagusMoney memory sarcophagusMoney = SarcophagusMoney({
            storageFee: storageFee,
            diggingFee: diggingFee,
            bounty: bounty,
            currentCursedBond: cursedBondAmount
        });

        sarcophaguses[assetDoubleHash] = sarcophagus;
        sarcophagusMonies[assetDoubleHash] = sarcophagusMoney;

        emit CreateSarcophagus(
            assetDoubleHash,
            sarcophagus.archaeologist,
            sarcophagus.embalmer,
            sarcophagus.name,
            sarcophagus.resurrectionTime,
            sarcophagus.resurrectionWindow,
            sarcophagusMoney.storageFee,
            sarcophagusMoney.diggingFee,
            sarcophagusMoney.bounty,
            sarcophagus.recipientPublicKey,
            sarcophagusMoney.currentCursedBond
        );

        return true;
    }

    function updateSarcophagus(
        bytes32 assetDoubleHash,
        string memory assetId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        Sarcophagus storage sarc = sarcophaguses[assetDoubleHash];

        require(
            sarc.state == SarcophagusStates.Exists,
            "sarcophagus does not exist"
        );
        require(
            sarc.embalmer == msg.sender,
            "sarcophagus can only be updated by embalmer"
        );
        require(
            bytes(sarc.assetId).length == 0,
            "assetId has already been set"
        );
        require(bytes(assetId).length > 0, "assetId must not have 0 length");

        address hopefullyArchAddress = ecrecover(
            keccak256(abi.encodePacked(assetId)),
            v,
            r,
            s
        );

        address archAddress = addressFromPublicKey(sarc.archaeologist);

        require(
            hopefullyArchAddress == archAddress,
            "signature did not come from archaeologist"
        );

        sarc.assetId = assetId;

        Archaeologist memory arch = archaeologists[archAddress];
        SarcophagusMoney memory sarcMoney = sarcophagusMonies[assetDoubleHash];
        sarcoToken.transfer(arch.paymentAddress, sarcMoney.storageFee);

        emit UpdateSarcophagus(assetDoubleHash, assetId);

        return true;
    }

    function cancelSarcophagus(bytes32 assetDoubleHash) public returns (bool) {
        Sarcophagus storage sarc = sarcophaguses[assetDoubleHash];

        require(
            sarc.state == SarcophagusStates.Exists,
            "sarcophagus does not exist"
        );
        require(
            bytes(sarc.assetId).length == 0,
            "cannot cancel because assetId is already set"
        );
        require(
            sarc.embalmer == msg.sender,
            "sarcophagus can only be cancelled by embalmer"
        );

        address archAddress = addressFromPublicKey(sarc.archaeologist);
        Archaeologist memory arch = archaeologists[archAddress];
        SarcophagusMoney memory sarcMoney = sarcophagusMonies[assetDoubleHash];

        sarcoToken.transfer(
            sarc.embalmer,
            sarcMoney.bounty.add(sarcMoney.storageFee)
        );
        sarcoToken.transfer(arch.paymentAddress, sarcMoney.diggingFee);

        archaeologistCancels[archAddress].push(assetDoubleHash);

        emit CancelSarcophagus(assetDoubleHash);

        return true;
    }

    function rewrapSarcophagus(
        bytes32 assetDoubleHash,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty
    ) public returns (bool) {
        Sarcophagus storage sarc = sarcophaguses[assetDoubleHash];

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

        address archAddress = addressFromPublicKey(sarc.archaeologist);
        Archaeologist memory arch = archaeologists[archAddress];

        require(
            resurrectionTime <= block.timestamp + arch.maximumResurrectionTime,
            "resurrection time too far in the future"
        );
        require(diggingFee >= arch.minimumDiggingFee, "digging fee is too low");
        require(bounty >= arch.minimumBounty, "bounty is too low");

        SarcophagusMoney storage sarcMoney = sarcophagusMonies[assetDoubleHash];
        sarcoToken.transfer(arch.paymentAddress, sarcMoney.diggingFee);

        // TODO: implment an algorithm to figure this out
        uint256 cursedBondAmount = diggingFee.add(bounty);

        if (cursedBondAmount > sarcMoney.currentCursedBond) {
            uint256 difference = cursedBondAmount.sub(
                sarcMoney.currentCursedBond
            );

            arch.freeBond = arch.freeBond.sub(
                difference,
                "archaeologist does not have enough free bond"
            );
            arch.cursedBond = arch.cursedBond.add(difference);
        } else if (cursedBondAmount < sarcMoney.currentCursedBond) {
            uint256 difference = sarcMoney.currentCursedBond.sub(
                cursedBondAmount
            );

            arch.freeBond = arch.freeBond.add(difference);
            arch.cursedBond = arch.cursedBond.sub(cursedBondAmount);
        }

        uint256 gracePeriod = (resurrectionTime.sub(block.timestamp)).div(100);
        if (gracePeriod < minimumResurrectionWindow) {
            gracePeriod = minimumResurrectionWindow;
        }

        sarc.resurrectionTime = resurrectionTime;
        sarcMoney.diggingFee = diggingFee;
        sarcMoney.bounty = bounty;
        sarcMoney.currentCursedBond = cursedBondAmount;
        sarc.resurrectionWindow = gracePeriod;

        emit RewrapSarcophagus(
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

    function unwrapSarcophagus(bytes32 assetDoubleHash, bytes memory singleHash)
        public
        returns (bool)
    {
        Sarcophagus storage sarc = sarcophaguses[assetDoubleHash];

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
            assetDoubleHash == keccak256(singleHash),
            "input hash does not match sarcophagus hash"
        );

        SarcophagusMoney memory sarcMoney = sarcophagusMonies[assetDoubleHash];
        address archAddress = addressFromPublicKey(sarc.archaeologist);
        Archaeologist storage arch = archaeologists[archAddress];

        sarcoToken.transfer(
            arch.paymentAddress,
            sarcMoney.diggingFee.add(sarcMoney.bounty)
        );

        arch.freeBond = arch.freeBond.add(sarcMoney.currentCursedBond);
        arch.cursedBond = arch.cursedBond.sub(sarcMoney.currentCursedBond);

        sarc.state = SarcophagusStates.Resurrected;

        // TODO: update cursed bond calculation

        emit UnwrapSarcophagus(sarc.assetId, assetDoubleHash, singleHash);

        return true;
    }
}
