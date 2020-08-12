// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.7.0;

contract Sarcophagus {
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
        address payable paymentAddress;
        uint256 minimumBounty;
        uint256 minimumDiggingFee;
        uint256 maximumResurrectionTime;
        uint256 freeBond;
        uint256 cursedBond;
    }

    mapping(address => Archaeologist) public archaeologists;
    address[] public archaeologistAddresses;

    function addArchaeologist(address user, Archaeologist memory arch)
        private
        returns (bool)
    {
        archaeologists[user] = arch;
        archaeologistAddresses.push(user);
        return true;
    }

    function archaeologistCount() public view returns (uint256) {
        return archaeologistAddresses.length;
    }

    function register(
        bytes memory publicKey,
        address payable paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime
    ) public payable returns (bool) {
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

        Archaeologist memory newArch = Archaeologist(
            true,
            publicKey,
            paymentAddress,
            minimumBounty,
            minimumDiggingFee,
            maximumResurrectionTime,
            msg.value,
            0
        );

        addArchaeologist(msg.sender, newArch);

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
        address payable paymentAddress,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime
    ) public payable exists returns (bool) {
        Archaeologist storage arch = archaeologists[msg.sender];
        require(arch.freeBond + msg.value >= arch.freeBond, "free bond overflow!");

        arch.paymentAddress = paymentAddress;
        arch.minimumBounty = minimumBounty;
        arch.minimumDiggingFee = minimumDiggingFee;
        arch.maximumResurrectionTime = maximumResurrectionTime;
        arch.freeBond += msg.value;

        emit UpdateArchaeologist(
            arch.publicKey,
            arch.paymentAddress,
            arch.minimumBounty,
            arch.minimumDiggingFee,
            arch.maximumResurrectionTime,
            msg.value
        );

        return true;
    }

    function withdrawalBond(uint256 amount) public exists returns (bool) {
        Archaeologist storage arch = archaeologists[msg.sender];
        require(
            arch.freeBond >= amount,
            "requested withdrawal amount is greater than free bond"
        );

        arch.paymentAddress.transfer(amount);
        arch.freeBond -= amount;

        emit WithdrawalFreeBond(arch.publicKey, amount);

        return true;
    }
}
