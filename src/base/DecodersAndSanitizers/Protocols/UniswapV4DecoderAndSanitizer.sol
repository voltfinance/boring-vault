// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {BaseDecoderAndSanitizer, DecoderCustomTypes} from "src/base/DecodersAndSanitizers/BaseDecoderAndSanitizer.sol";
import {IUniswapV4PositionManager} from "src/interfaces/RawDataDecoderAndSanitizerInterfaces.sol"; 
import {Actions, Commands} from "src/interfaces/UniswapV4Actions.sol"; 

abstract contract UniswapV4DecoderAndSanitizer is BaseDecoderAndSanitizer {
    //============================== ERRORS ===============================

    error UniswapV4DecoderAndSanitizer__NotSwapInput(); 
    error UniswapV4DecoderAndSanitizer__NotSwapSubAction(); 
    error UniswapV4DecoderAndSanitizer__UnsupportedAction(); 
    error UniswapV4DecoderAndSanitizer__UnsupportedSubAction(); 
    error UniswapV4DecoderAndSanitizer__SubActionLength(); 

    //============================== Immutables ===============================
    IUniswapV4PositionManager posm; 

    //============================== Constructor ===============================
    constructor(address _posm) {
        posm = IUniswapV4PositionManager(_posm); 
    }
   
    //============================== Universal Router ===============================
    
    // @dev in order to sanitize we require that only command be passed in a time. This defeats the ability to batch commands together, but is necessary to avoid having a gajillion leaves for all possible orders that can be used here
    // @dev inputs can be grouped together based on common things, ie. swaps will always be swap, settle, take, etc. 
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 /*deadline*/) external pure returns (bytes memory addressesFound) {
        // Verify exactly 1 byte
        require(commands.length == 1, "Invalid commands length");
        // Extract and verify command
        uint8 command = uint8(commands[0]);
        if (command == uint8(Commands.V4_SWAP)) {

            // Extract the path from PoolKey
            (bytes memory actions, bytes[] memory params) = abi.decode(inputs[0], (bytes, bytes[]));

            if (uint8(actions[0]) == uint8(Actions.SWAP_EXACT_IN_SINGLE) || uint8(actions[0]) == uint8(Actions.SWAP_EXACT_OUT_SINGLE)) { 

                // Decode the first param which should be our ExactInputSingleParams/ExactOutputSingleParams struct (same fields)
                DecoderCustomTypes.ExactInputSingleParams memory swapParams = abi.decode(params[0], (DecoderCustomTypes.ExactInputSingleParams));

                // Extract addresses from poolKey
                address currency0 = address(swapParams.poolKey.currency0);
                address currency1 = address(swapParams.poolKey.currency1);
                address hook = address(swapParams.poolKey.hooks);

                //verify we are SETTLING, and then TAKING
                if (uint8(actions[1]) != uint8(Actions.SETTLE_ALL)) revert UniswapV4DecoderAndSanitizer__NotSwapSubAction(); 
                if (uint8(actions[2]) != uint8(Actions.TAKE_ALL)) revert UniswapV4DecoderAndSanitizer__NotSwapSubAction(); 

                (address currencyToSpend, ) = abi.decode(params[1], (address, uint128)); 
                (address currencyToReceive, ) = abi.decode(params[2], (address, uint128)); 

                addressesFound = abi.encodePacked(currency0, currency1, hook, currencyToSpend, currencyToReceive);  
            } else {
                revert UniswapV4DecoderAndSanitizer__UnsupportedAction(); 
            }
        } else {
            //only support v4 swaps via the universal router
            revert UniswapV4DecoderAndSanitizer__NotSwapInput();  
        }
    }

    //============================== Permit2 ===============================
    
    function approve(address token, address spender, uint160 /*amount*/, uint48 /*expiraton*/) external pure returns (bytes memory addressesFound) {
        addressesFound = abi.encodePacked(token, spender); 
    } 

    //============================== Position Manager ===============================
    
    function modifyLiquidities(bytes calldata unlockData, uint256 /*deadline*/) external view returns (bytes memory addressesFound) { 
        // First decode the outer tuple (actions, params)
        (bytes memory actions, bytes[] memory params) = abi.decode(unlockData, (bytes, bytes[]));
        
        //only support 1 action at a time (which can have up to 2 subactions, so 3 actions total)
        if (actions.length > 3) revert UniswapV4DecoderAndSanitizer__SubActionLength(); 
        
        uint8 action = uint8(bytes1(actions[0]));
        if (action == uint8(Actions.MINT_POSITION)) {

             (
                DecoderCustomTypes.PoolKey memory poolKey,
                /*int24 tickLower*/,
                /*int24 tickUpper*/,
                /*uint256 liquidity*/,
                /*uint128 amount0Max*/,
                /*uint128 amount1Max*/,
                address recipient,
                /*bytes memory hookData*/
            ) = abi.decode(params[0], (DecoderCustomTypes.PoolKey, int24, int24, uint256, uint128, uint128, address, bytes));
            
            // Ensure we're settling next, and then settling the correct pair 
            uint8 subAction = uint8(bytes1(actions[1]));
            if (subAction != uint8(Actions.SETTLE_PAIR)) revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction(); 

            (address currency0Settle, address currency1Settle) = abi.decode(params[1], (address, address)); 
              
            addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, poolKey.hooks, recipient, currency0Settle, currency1Settle); 
            return addressesFound;             
         
        } else if (action == uint8(Actions.INCREASE_LIQUIDITY)) {

             (
                uint256 tokenId,
                /*uint256 liquidity*/,
                /*uint128 amount0Max*/,
                /*uint128 amount1Max*/,
                /*bytes memory hookData*/
            ) = abi.decode(params[0], (uint256, uint256, uint128, uint128, bytes));

            (DecoderCustomTypes.PoolKey memory poolKey, ) = posm.getPoolAndPositionInfo(tokenId); 
              
            uint8 subAction = uint8(bytes1(actions[1])); 
            
            uint8 subAction1;  
            if (actions.length > 2) {
                subAction1 = uint8(bytes1(actions[2])); 
            }
            
            if (subAction == uint8(Actions.SETTLE_PAIR)) {
                (address currency0Settle, address currency1Settle) = abi.decode(params[1], (address, address)); 
                
                return addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, currency0Settle, currency1Settle); 

            } else if (subAction == uint8(Actions.CLOSE_CURRENCY)) {
                //if the length is too short, we revert w/ unsupported
                if (actions.length <= 2) revert UniswapV4DecoderAndSanitizer__SubActionLength(); 

                //if the first subaction is CLOSE_CURRENCY, we decode that param
                //NOTE: The second subaction does not need to be CLOSE_CURRENCY, so we have to check both paths  
                //both result in the same sanitization, but are decoded differently

                (address currency0Settle) = abi.decode(params[1], (address)); 
                address currency1Settle;  
                    if (subAction1 == uint8(Actions.CLOSE_CURRENCY)) {
                        (currency1Settle) = abi.decode(params[2], (address)); 

                    } else if (subAction1 == uint8(Actions.CLEAR_OR_TAKE)) {
                        (currency1Settle, ) = abi.decode(params[2], (address, uint256)); 
                    } else {
                        // If somehow anything else is passed here, we revert
                        revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction();     
                    } 
                
                // Return currency0, currency1
                return addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, currency0Settle, currency1Settle); 

            } else if (subAction == uint8(Actions.CLEAR_OR_TAKE)) {
                if (actions.length <= 2) revert UniswapV4DecoderAndSanitizer__SubActionLength(); 

                (address currency0Settle, ) = abi.decode(params[1], (address, uint256)); 
                address currency1Settle;  

                    if (subAction1 == uint8(Actions.CLOSE_CURRENCY)) {
                        (currency1Settle) = abi.decode(params[2], (address)); 

                    } else if (subAction1 == uint8(Actions.CLEAR_OR_TAKE)) {
                        (currency1Settle, ) = abi.decode(params[2], (address, uint256)); 
                    } else {
                        // If somehow anything else is passed here, we revert
                        revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction();     
                    } 

                // Return currency0, currency1
                return addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, currency0Settle, currency1Settle); 

            } else {
                revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction(); 
            }

        } else if (action == uint8(Actions.DECREASE_LIQUIDITY)) {
             (
                uint256 tokenId,
                /*uint256 liquidity*/,
                /*uint128 amount0Max*/,
                /*uint128 amount1Max*/,
                /*bytes memory hookData*/
            ) = abi.decode(params[0], (uint256, uint256, uint128, uint128, bytes));

            (DecoderCustomTypes.PoolKey memory poolKey, ) = posm.getPoolAndPositionInfo(tokenId); 
            
            // Get the subaction 
            uint8 subAction = uint8(bytes1(actions[1])); 
            
            // Check the length
            uint8 subAction1;  
            if (actions.length > 2) {
                subAction1 = uint8(bytes1(actions[2])); 
            }

            if (subAction == uint8(Actions.TAKE_PAIR)) {
               
                (address currency0Settle, address currency1Settle, address recipient) = abi.decode(params[1], (address, address, address)); 

                return addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, currency0Settle, currency1Settle, recipient); 
                
            // Supported but not recommended
            } else if (subAction == uint8(Actions.CLOSE_CURRENCY)) {
                //if the length is too short, we revert w/ unsupported
                if (actions.length <= 2) revert UniswapV4DecoderAndSanitizer__SubActionLength(); 

                //if the first subaction is CLOSE_CURRENCY, we decode that param
                //NOTE: The second subaction does not need to be CLOSE_CURRENCY, so we have to check both paths  

                (address currency0Settle) = abi.decode(params[1], (address)); 
                address currency1Settle;  

                    if (subAction1 == uint8(Actions.CLOSE_CURRENCY)) {
                        (currency1Settle) = abi.decode(params[2], (address)); 

                    } else if (subAction1 == uint8(Actions.CLEAR_OR_TAKE)) {
                        (currency1Settle, ) = abi.decode(params[2], (address, uint256)); 
                    } else {
                        revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction();     
                    } 

                return addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, currency0Settle, currency1Settle); 

            } else if (subAction == uint8(Actions.CLEAR_OR_TAKE)) {
                if (actions.length <= 2) revert UniswapV4DecoderAndSanitizer__SubActionLength(); 

                (address currency0Settle, ) = abi.decode(params[1], (address, uint256)); 
                address currency1Settle;  

                    if (subAction1 == uint8(Actions.CLOSE_CURRENCY)) {
                        (currency1Settle) = abi.decode(params[2], (address)); 

                    } else if (subAction1 == uint8(Actions.CLEAR_OR_TAKE)) {
                        (currency1Settle, ) = abi.decode(params[2], (address, uint256)); 
                    } else {
                        revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction();     
                    } 

                return addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, currency0Settle, currency1Settle); 

            } else {
                revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction(); 
            }
        } else if (action == uint8(Actions.BURN_POSITION)) {

             (
                uint256 tokenId,
                /*uint128 amount0Max*/,
                /*uint128 amount1Max*/,
                /*bytes memory hookData*/
            ) = abi.decode(params[0], (uint256, uint128, uint128, bytes));

            (DecoderCustomTypes.PoolKey memory poolKey, ) = posm.getPoolAndPositionInfo(tokenId); 
            
            uint8 subAction = uint8(bytes1(actions[1])); 
            if (subAction == uint8(Actions.TAKE_PAIR)) {
                (address currency0Settle, address currency1Settle, address recipient) = abi.decode(params[1], (address, address, address)); 
                addressesFound = abi.encodePacked(poolKey.currency0, poolKey.currency1, currency0Settle, currency1Settle, recipient); 
            } else {
                revert UniswapV4DecoderAndSanitizer__UnsupportedSubAction(); 
            }
        } else {
            revert UniswapV4DecoderAndSanitizer__UnsupportedAction(); 
        }
    }
}
