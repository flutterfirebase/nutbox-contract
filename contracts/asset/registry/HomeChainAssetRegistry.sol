// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '../interfaces/IAssetRegistry.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract HomeChainAssetRegistry is IAssetRegistry, Ownable {

    address public registryHub;

    event HomeChainAssetRegistered(
        address indexed owner,
        address indexed homeLocation
    );

    constructor(address _registryHub) {
        require(_registryHub != address(0), 'Invalid registry hub address');
        registryHub = _registryHub;
    }

    function setRegistryHub(address _registryHub) public onlyOwner {
        require(_registryHub != address(0), 'Invalid registry hub address');
        registryHub = _registryHub;
    }

    function registerAsset(bytes memory foreignLocation, address homeLocation, bytes memory properties) external override {

        require(foreignLocation.length == 0, 'HomeChainAssetRegistry: invalid foreignLocation format');
        require(homeLocation != address(0), 'HomeChainAssetRegistry: homeLocation should not be 0');

        bytes32 assetId = keccak256(abi.encodePacked(foreignLocation, homeLocation));
        bytes memory data = abi.encodeWithSignature(
            "add(address,bytes32,address,bytes,bool)",
            msg.sender,
            assetId,
            homeLocation,
            foreignLocation,
            false
        );

        (bool success,) = registryHub.call(data);
        require(success, "failed to call register bub");

        emit HomeChainAssetRegistered(msg.sender, homeLocation);
    }
}
