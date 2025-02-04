// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {BaseDecoderAndSanitizer, DecoderCustomTypes} from "src/base/DecodersAndSanitizers/BaseDecoderAndSanitizer.sol";

abstract contract InfraredDecoderAndSanitizer is BaseDecoderAndSanitizer {
    
    function stake(uint256 /*amount*/) external pure virtual returns (bytes memory addressesFound) {
        return addressesFound; 
    }

    function withdraw(uint256 /*amount*/) external pure virtual returns (bytes memory addressesFound) {
        return addressesFound; 
    }

    function getRewardForUser(address _user) external pure virtual returns (bytes memory addressesFound) {
        addressesFound = abi.encodePacked(_user); 
    }
    
    //sends rewards to msg.sender
    function getReward() external pure virtual returns (bytes memory addressesFound) {
        return addressesFound; 
    }
    
    //calls both getReward() and withdraw()
    function exit() external pure virtual returns (bytes memory addressesFound) {
        return addressesFound; 
    }
}
