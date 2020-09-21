// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Utils.sol";
import "./Events.sol";
import "./Types.sol";
import "./Datas.sol";

library Archaeologists {
    using SafeMath for uint256;

    function archaeologistExists(
        Datas.Data storage data,
        address addy,
        bool huh
    ) public view {
        string memory err = "archaeologist has not been registered yet";
        if (!huh) err = "archaeologist has already been registered";
        require(data.archaeologists[addy].exists == huh, err);
    }

    function increaseFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        Types.Archaeologist storage arch = data.archaeologists[archAddress];
        arch.freeBond = arch.freeBond.add(amount);
    }

    function reduceFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        Types.Archaeologist storage arch = data.archaeologists[archAddress];
        arch.freeBond = arch.freeBond.sub(
            amount,
            "archaeologist does not have enough free bond"
        );
    }

    function increaseCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        Types.Archaeologist storage arch = data.archaeologists[archAddress];
        arch.cursedBond = arch.cursedBond.add(amount);
    }

    function reduceCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        Types.Archaeologist storage arch = data.archaeologists[archAddress];
        arch.cursedBond = arch.cursedBond.sub(amount);
    }

    function lockUpBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        reduceFreeBond(data, archAddress, amount);
        increaseCursedBond(data, archAddress, amount);
    }

    function freeUpBond(
        Datas.Data storage self,
        address archAddress,
        uint256 amount
    ) public {
        increaseFreeBond(self, archAddress, amount);
        reduceCursedBond(self, archAddress, amount);
    }

    function registerArchaeologist(
        Datas.Data storage self,
        bytes memory publicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (bool) {
        archaeologistExists(self, msg.sender, false);
        Utils.publicKeyLength(publicKey);
        Utils.publicKeyAccuracy(publicKey, msg.sender);

        sarcoToken.transferFrom(msg.sender, address(this), freeBond);

        Types.Archaeologist memory newArch = Types.Archaeologist({
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

        self.archaeologists[msg.sender] = newArch;
        self.archaeologistAddresses.push(msg.sender);

        emit Events.RegisterArchaeologist(
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
        Datas.Data storage self,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (bool) {
        archaeologistExists(self, msg.sender, true);

        Types.Archaeologist storage arch = self.archaeologists[msg.sender];
        arch.endpoint = endpoint;
        arch.paymentAddress = paymentAddress;
        arch.feePerByte = feePerByte;
        arch.minimumBounty = minimumBounty;
        arch.minimumDiggingFee = minimumDiggingFee;
        arch.maximumResurrectionTime = maximumResurrectionTime;

        increaseFreeBond(self, msg.sender, freeBond);

        if (freeBond > 0) {
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        emit Events.UpdateArchaeologist(
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

    function withdrawBond(
        Datas.Data storage self,
        uint256 amount,
        IERC20 sarcoToken
    ) public returns (bool) {
        archaeologistExists(self, msg.sender, true);
        Types.Archaeologist storage arch = self.archaeologists[msg.sender];
        reduceFreeBond(self, msg.sender, amount);
        sarcoToken.transfer(arch.paymentAddress, amount);
        emit Events.WithdrawalFreeBond(arch.publicKey, amount);
        return true;
    }
}
