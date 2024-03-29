// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Types {
    struct Distribution {
        // if current block height > stopHeight, this distribution passed.
        bool hasPassed;
        // rewards per block of this distribution.
        uint256 amount;
        // when current block height > startHeight, distribution was enabled.
        uint256 startHeight;
        // when curent block height > stopHeight, distribution was disabled
        uint256 stopHeight;
    }

    struct Asset {
        // asset id: should be keccak256(abi.encodePacked(foreignLocationLen, foreignLocation, homeLocation));
        bytes32 id;
        // crosschain asset location identity
        bytes foreignLocation;
        // binding a deployed ERC20 token address
        address homeLocation;
        // mark whether asset is valid
        bool valid;
    }
}
