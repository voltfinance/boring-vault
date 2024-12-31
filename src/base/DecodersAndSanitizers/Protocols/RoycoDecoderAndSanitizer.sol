// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {BaseDecoderAndSanitizer, DecoderCustomTypes} from "src/base/DecodersAndSanitizers/BaseDecoderAndSanitizer.sol";

abstract contract RoycoWeirollDecoderAndSanitizer is BaseDecoderAndSanitizer {

       function fillIPOffers(
        bytes32[] calldata ipOfferHashes,
        uint256[] calldata fillAmounts,
        address fundingVault,
        address frontendFeeRecipient
    ) 
}
