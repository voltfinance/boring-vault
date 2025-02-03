// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC4626} from "@solmate/tokens/ERC4626.sol";
import {MerkleTreeHelper} from "test/resources/MerkleTreeHelper/MerkleTreeHelper.sol";
import "forge-std/Script.sol";

/**
 *  source .env && forge script script/MerkleRootCreation/Mainnet/CreateMultiChainLiquidEthMerkleRoot.s.sol --rpc-url $MAINNET_RPC_URL
 */
contract CreateMultiChainLiquidEthMerkleRootScript is Script, MerkleTreeHelper {
    using FixedPointMathLib for uint256;

    address public boringVault = 0xf0bb20865277aBd641a307eCe5Ee04E79073416C;
    address public rawDataDecoderAndSanitizer = 0xB0D19CDA2BD3035767CDb5D81cB387976De52117;
    address public managerAddress = 0x227975088C28DBBb4b421c6d96781a53578f19a8;
    address public accountantAddress = 0x0d05D94a5F1E76C18fbeB7A13d17C8a314088198;
    address public pancakeSwapDataDecoderAndSanitizer = 0xfdC73Fc6B60e4959b71969165876213918A443Cd;
    address public itbDecoderAndSanitizer = 0xEEb53299Cb894968109dfa420D69f0C97c835211;
    address public itbAaveDecoderAndSanitizer = 0x7fA5dbDB1A76d2990Ea0f3c74e520E3fcE94748B;
    address public itbReserveProtocolPositionManager = 0x778aC5d0EE062502fADaa2d300a51dE0869f7995;
    address public itbAaveLidoPositionManager = 0xC4F5Ee078a1C4DA280330546C29840d45ab32753;
    address public itbAaveLidoPositionManager2 = 0x572F323Aa330B467C356c5a30Bf9A20480F4fD52;
    address public hyperlaneDecoderAndSanitizer = 0xfC823909C7D2Cb8701FE7d6EE74508C57Df1D6dE;
    address public termFinanceDecoderAndSanitizer = 0xF8e9517e7e98D7134E306aD3747A50AC8dC1dbc9;

    function setUp() external {}

    /**
     * @notice Uncomment which script you want to run.
     */
    function run() external {
        generateLiquidEthStrategistMerkleRoot();
    }

    function generateLiquidEthStrategistMerkleRoot() public {
        setSourceChainName(mainnet);
        setAddress(false, mainnet, "boringVault", boringVault);
        setAddress(false, mainnet, "managerAddress", managerAddress);
        setAddress(false, mainnet, "accountantAddress", accountantAddress);
        setAddress(false, mainnet, "rawDataDecoderAndSanitizer", rawDataDecoderAndSanitizer);

        ManageLeaf[] memory leafs = new ManageLeaf[](2048);

        // ========================== Aave V3 ==========================
        ERC20[] memory supplyAssets = new ERC20[](3);
        supplyAssets[0] = getERC20(sourceChain, "WETH");
        supplyAssets[1] = getERC20(sourceChain, "WEETH");
        supplyAssets[2] = getERC20(sourceChain, "WSTETH");
        ERC20[] memory borrowAssets = new ERC20[](3);
        borrowAssets[0] = getERC20(sourceChain, "WETH");
        borrowAssets[1] = getERC20(sourceChain, "WEETH");
        borrowAssets[2] = getERC20(sourceChain, "WSTETH");
        _addAaveV3Leafs(leafs, supplyAssets, borrowAssets);

        // ========================== SparkLend ==========================
        borrowAssets = new ERC20[](3);
        borrowAssets[0] = getERC20(sourceChain, "WETH");
        borrowAssets[1] = getERC20(sourceChain, "WSTETH");
        borrowAssets[2] = getERC20(sourceChain, "RETH");
        _addSparkLendLeafs(leafs, supplyAssets, borrowAssets);

        // ========================== Aave V3 Lido ==========================
        supplyAssets = new ERC20[](2);
        supplyAssets[0] = getERC20(sourceChain, "WETH");
        supplyAssets[1] = getERC20(sourceChain, "WSTETH");
        borrowAssets = new ERC20[](1);
        borrowAssets[0] = getERC20(sourceChain, "WETH");
        _addAaveV3LidoLeafs(leafs, supplyAssets, borrowAssets);

        // ========================== Lido ==========================
        _addLidoLeafs(leafs);

        // ========================== EtherFi ==========================
        /**
         * stake, unstake, wrap, unwrap
         */
        _addEtherFiLeafs(leafs);

        // ========================== Native ==========================
        /**
         * wrap, unwrap
         */
        _addNativeLeafs(leafs);

        // ========================== Gearbox ==========================
        _addGearboxLeafs(leafs, ERC4626(getAddress(sourceChain, "dWETHV3")), getAddress(sourceChain, "sdWETHV3"));

        // ========================== MorphoBlue ==========================
        /**
         * weETH/wETH  86.00 LLTV market 0x698fe98247a40c5771537b5786b2f3f9d78eb487b4ce4d75533cd0e94d88a115
         */
        _addMorphoBlueSupplyLeafs(leafs, 0x698fe98247a40c5771537b5786b2f3f9d78eb487b4ce4d75533cd0e94d88a115);

        // ========================== Meta Morpho ==========================
        _addERC4626Leafs(leafs, ERC4626(getAddress(sourceChain, "gauntletWETHPrime")));
        _addERC4626Leafs(leafs, ERC4626(getAddress(sourceChain, "gauntletWETHCore")));
        _addERC4626Leafs(leafs, ERC4626(getAddress(sourceChain, "mevCapitalwWeth")));
        _addERC4626Leafs(leafs, ERC4626(getAddress(sourceChain, "Re7WETH")));

        // ========================== Pendle ==========================
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleWeETHMarket"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleZircuitWeETHMarket"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleWeETHMarketSeptember"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleWeETHMarketDecember"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleKarakWeETHMarketSeptember"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleZircuitWeETHMarketAugust"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleWeETHMarketJuly"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendle_weETHs_market_08_28_24"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleWeETHkSeptember"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendle_weETHs_market_12_25_24"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleKarakWeETHMarketDecember"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendleWeETHkDecember"), true);
        _addPendleMarketLeafs(leafs, getAddress(sourceChain, "pendle_liquid_bera_eth_04_09_25"), true);

        // ========================== UniswapV3 ==========================
        address[] memory token0 = new address[](9);
        token0[0] = getAddress(sourceChain, "WETH");
        token0[1] = getAddress(sourceChain, "WETH");
        token0[2] = getAddress(sourceChain, "WETH");
        token0[3] = getAddress(sourceChain, "WEETH");
        token0[4] = getAddress(sourceChain, "WEETH");
        token0[5] = getAddress(sourceChain, "WSTETH");
        token0[6] = getAddress(sourceChain, "WETH");
        token0[7] = getAddress(sourceChain, "WETH");
        token0[8] = getAddress(sourceChain, "WETH");

        address[] memory token1 = new address[](9);
        token1[0] = getAddress(sourceChain, "WEETH");
        token1[1] = getAddress(sourceChain, "WSTETH");
        token1[2] = getAddress(sourceChain, "RETH");
        token1[3] = getAddress(sourceChain, "WSTETH");
        token1[4] = getAddress(sourceChain, "RETH");
        token1[5] = getAddress(sourceChain, "RETH");
        token1[6] = getAddress(sourceChain, "SFRXETH");
        token1[7] = getAddress(sourceChain, "CBETH");
        token1[8] = getAddress(sourceChain, "RSETH");

        _addUniswapV3Leafs(leafs, token0, token1, false);

        // ========================== Fee Claiming ==========================
        /**
         * Claim fees in USDC, DAI, USDT and USDE
         */
        ERC20[] memory feeAssets = new ERC20[](3);
        feeAssets[0] = getERC20(sourceChain, "WETH");
        feeAssets[1] = getERC20(sourceChain, "WEETH");
        feeAssets[2] = getERC20(sourceChain, "EETH");
        _addLeafsForFeeClaiming(leafs, getAddress(sourceChain, "accountantAddress"), feeAssets, false);

        // ========================== 1inch ==========================
        address[] memory assets = new address[](16);
        SwapKind[] memory kind = new SwapKind[](16);
        assets[0] = getAddress(sourceChain, "WETH");
        kind[0] = SwapKind.BuyAndSell;
        assets[1] = getAddress(sourceChain, "WEETH");
        kind[1] = SwapKind.BuyAndSell;
        assets[2] = getAddress(sourceChain, "WSTETH");
        kind[2] = SwapKind.BuyAndSell;
        assets[3] = getAddress(sourceChain, "RETH");
        kind[3] = SwapKind.BuyAndSell;
        assets[4] = getAddress(sourceChain, "GEAR");
        kind[4] = SwapKind.Sell;
        assets[5] = getAddress(sourceChain, "CRV");
        kind[5] = SwapKind.Sell;
        assets[6] = getAddress(sourceChain, "CVX");
        kind[6] = SwapKind.Sell;
        assets[7] = getAddress(sourceChain, "AURA");
        kind[7] = SwapKind.Sell;
        assets[8] = getAddress(sourceChain, "BAL");
        kind[8] = SwapKind.Sell;
        assets[9] = getAddress(sourceChain, "PENDLE");
        kind[9] = SwapKind.Sell;
        assets[10] = getAddress(sourceChain, "SFRXETH");
        kind[10] = SwapKind.BuyAndSell;
        assets[11] = getAddress(sourceChain, "INST");
        kind[11] = SwapKind.Sell;
        assets[12] = getAddress(sourceChain, "RSR");
        kind[12] = SwapKind.Sell;
        assets[13] = getAddress(sourceChain, "CBETH");
        kind[13] = SwapKind.BuyAndSell;
        assets[14] = getAddress(sourceChain, "RSETH");
        kind[14] = SwapKind.BuyAndSell;
        assets[15] = getAddress(sourceChain, "CAKE");
        kind[15] = SwapKind.Sell;
        _addLeafsFor1InchGeneralSwapping(leafs, assets, kind);

        _addLeafsFor1InchUniswapV3Swapping(leafs, getAddress(sourceChain, "wstETH_wETH_01"));
        _addLeafsFor1InchUniswapV3Swapping(leafs, getAddress(sourceChain, "rETH_wETH_01"));
        _addLeafsFor1InchUniswapV3Swapping(leafs, getAddress(sourceChain, "rETH_wETH_05"));
        _addLeafsFor1InchUniswapV3Swapping(leafs, getAddress(sourceChain, "wstETH_rETH_05"));
        _addLeafsFor1InchUniswapV3Swapping(leafs, getAddress(sourceChain, "PENDLE_wETH_30"));
        _addLeafsFor1InchUniswapV3Swapping(leafs, getAddress(sourceChain, "wETH_weETH_05"));
        _addLeafsFor1InchUniswapV3Swapping(leafs, getAddress(sourceChain, "GEAR_wETH_100"));

        // ========================== Curve Swapping ==========================
        _addLeafsForCurveSwapping(leafs, getAddress(sourceChain, "weETH_wETH_Pool"));
        _addLeafsForCurveSwapping(leafs, getAddress(sourceChain, "weETH_wETH_NG_Pool"));
        _addLeafsForCurveSwapping(leafs, getAddress(sourceChain, "tETH_wstETH_curve_pool"));

        // ========================== Swell ==========================
        _addSwellSimpleStakingLeafs(
            leafs, getAddress(sourceChain, "WEETH"), getAddress(sourceChain, "swellSimpleStaking")
        );
        _addSwellSimpleStakingLeafs(
            leafs, getAddress(sourceChain, "WSTETH"), getAddress(sourceChain, "swellSimpleStaking")
        );
        _addSwellSimpleStakingLeafs(
            leafs, getAddress(sourceChain, "SFRXETH"), getAddress(sourceChain, "swellSimpleStaking")
        );
        _addSwellSimpleStakingLeafs(
            leafs, getAddress(sourceChain, "pendleEethPt"), getAddress(sourceChain, "swellSimpleStaking")
        );
        _addSwellSimpleStakingLeafs(
            leafs, getAddress(sourceChain, "pendleEethPtDecember"), getAddress(sourceChain, "swellSimpleStaking")
        );
        _addSwellSimpleStakingLeafs(
            leafs, getAddress(sourceChain, "pendleEethPtSeptember"), getAddress(sourceChain, "swellSimpleStaking")
        );
        _addSwellSimpleStakingLeafs(
            leafs, getAddress(sourceChain, "pendleZircuitEethPt"), getAddress(sourceChain, "swellSimpleStaking")
        );

        // ========================== Zircuit ==========================
        _addZircuitLeafs(leafs, getAddress(sourceChain, "WEETH"), getAddress(sourceChain, "zircuitSimpleStaking"));
        _addZircuitLeafs(leafs, getAddress(sourceChain, "WSTETH"), getAddress(sourceChain, "zircuitSimpleStaking"));

        // ========================== Balancer ==========================
        _addBalancerLeafs(leafs, getBytes32(sourceChain, "rETH_weETH_id"), getAddress(sourceChain, "rETH_weETH_gauge"));
        _addBalancerLeafs(leafs, getBytes32(sourceChain, "rETH_wETH_id"), getAddress(sourceChain, "rETH_wETH_gauge"));
        _addBalancerLeafs(
            leafs, getBytes32(sourceChain, "wstETH_wETH_Id"), getAddress(sourceChain, "wstETH_wETH_Gauge")
        );
        _addBalancerLeafs(leafs, getBytes32(sourceChain, "rsETH_wETH_id"), getAddress(sourceChain, "rsETH_wETH_gauge"));

        // ========================== Aura ==========================
        _addAuraLeafs(leafs, getAddress(sourceChain, "aura_reth_weeth"));
        _addAuraLeafs(leafs, getAddress(sourceChain, "aura_reth_weth"));
        _addAuraLeafs(leafs, getAddress(sourceChain, "aura_wstETH_wETH"));
        _addAuraLeafs(leafs, getAddress(sourceChain, "aura_rsETH_wETH"));

        // ========================== Flashloans ==========================
        _addBalancerFlashloanLeafs(leafs, getAddress(sourceChain, "WETH"));
        _addBalancerFlashloanLeafs(leafs, getAddress(sourceChain, "WEETH"));

        // ========================== Fluid fToken ==========================
        _addFluidFTokenLeafs(leafs, getAddress(sourceChain, "fWETH"));
        _addFluidFTokenLeafs(leafs, getAddress(sourceChain, "fWSTETH"));

        // ========================== FrxEth ==========================
        /**
         * deposit, withdraw
         */
        _addERC4626Leafs(leafs, ERC4626(getAddress(sourceChain, "SFRXETH")));

        // ========================== Curve ==========================
        _addCurveLeafs(
            leafs, getAddress(sourceChain, "weETH_wETH_ng"), 2, getAddress(sourceChain, "weETH_wETH_ng_gauge")
        );

        // ========================== Convex ==========================
        _addConvexLeafs(
            leafs, getERC20(sourceChain, "weETH_wETH_NG_Pool"), getAddress(sourceChain, "weETH_wETH_NG_Convex_Reward")
        );

        // ========================== BoringVaults ==========================
        {
            ERC20[] memory tellerAssets = new ERC20[](11);
            tellerAssets[0] = getERC20(sourceChain, "WETH");
            tellerAssets[1] = getERC20(sourceChain, "EETH");
            tellerAssets[2] = getERC20(sourceChain, "WEETH");
            tellerAssets[3] = getERC20(sourceChain, "WSTETH");
            tellerAssets[4] = getERC20(sourceChain, "CBETH");
            tellerAssets[5] = getERC20(sourceChain, "WBETH");
            tellerAssets[6] = getERC20(sourceChain, "RETH");
            tellerAssets[7] = getERC20(sourceChain, "METH");
            tellerAssets[8] = getERC20(sourceChain, "SWETH");
            tellerAssets[9] = getERC20(sourceChain, "SFRXETH");
            tellerAssets[10] = getERC20(sourceChain, "ETHX");
            address superSymbioticTeller = 0x99dE9e5a3eC2750a6983C8732E6e795A35e7B861;
            _addTellerLeafs(leafs, superSymbioticTeller, tellerAssets);

            tellerAssets = new ERC20[](13);
            tellerAssets[0] = getERC20(sourceChain, "WETH");
            tellerAssets[1] = getERC20(sourceChain, "EETH");
            tellerAssets[2] = getERC20(sourceChain, "WEETH");
            tellerAssets[3] = getERC20(sourceChain, "WSTETH");
            tellerAssets[4] = getERC20(sourceChain, "CBETH");
            tellerAssets[5] = getERC20(sourceChain, "WBETH");
            tellerAssets[6] = getERC20(sourceChain, "RETH");
            tellerAssets[7] = getERC20(sourceChain, "METH");
            tellerAssets[8] = getERC20(sourceChain, "SWETH");
            tellerAssets[9] = getERC20(sourceChain, "SFRXETH");
            tellerAssets[10] = getERC20(sourceChain, "ETHX");
            tellerAssets[11] = getERC20(sourceChain, "RSWETH");
            tellerAssets[12] = getERC20(sourceChain, "RSETH");
            address kingKarakTeller = 0x929B44db23740E65dF3A81eA4aAB716af1b88474;
            _addTellerLeafs(leafs, kingKarakTeller, tellerAssets);
        }

        // ========================== Fluid Dex ==========================
        {
            ERC20[] memory supplyTokens = new ERC20[](2);
            supplyTokens[0] = getERC20(sourceChain, "WEETH");
            supplyTokens[1] = getERC20(sourceChain, "WETH");

            ERC20[] memory borrowTokens = new ERC20[](1);
            borrowTokens[0] = getERC20(sourceChain, "WSTETH");

            uint256 dexType = 2000;

            _addFluidDexLeafs(
                leafs, getAddress(sourceChain, "weETH_ETHDex_wstETH"), dexType, supplyTokens, borrowTokens
            );
        }

        // ========================== Euler ==========================
        {
            ERC4626[] memory depositVaults = new ERC4626[](1); 
            depositVaults[0] = ERC4626(getAddress(sourceChain, "eulerPrimeWETH")); 
            
            address[] memory subaccounts = new address[](1); 
            subaccounts[0] = address(boringVault); 

            _addEulerDepositLeafs(leafs, depositVaults, subaccounts); 

        }        

        // ========================== Term ==========================
        {
            setAddress(true, sourceChain, "rawDataDecoderAndSanitizer", termFinanceDecoderAndSanitizer);
            ERC20[] memory purchaseTokens = new ERC20[](2);
            purchaseTokens[0] = getERC20(sourceChain, "WETH");
            purchaseTokens[1] = getERC20(sourceChain, "WETH");
            address[] memory termAuctionOfferLockerAddresses = new address[](2);
            termAuctionOfferLockerAddresses[0] = 0x8b051F8Bc836EC4B01da563dB82df9CD22CA4884;
            termAuctionOfferLockerAddresses[1] = 0x8a98076a97dc3e905b6beEb47268a92658bCf9C1;
            address[] memory termRepoLockers = new address[](2);
            termRepoLockers[0] = 0x330e701F0523b445958f0484E6Ea3656c55932A4;
            termRepoLockers[1] = 0x46044AccFa442cDd1f4958847CC05F01a59b9610;
            address[] memory termRepoServicers = new address[](2);
            termRepoServicers[0] = 0x4895958D1F170Db5fD71bcf3B2cE0dA40A0e38FF;
            termRepoServicers[1] = 0x859B4aDc287E76fe7076F6Af9bfB56e3E9253c1c;
            _addTermFinanceLockOfferLeafs(leafs, purchaseTokens, termAuctionOfferLockerAddresses, termRepoLockers);
            _addTermFinanceUnlockOfferLeafs(leafs, termAuctionOfferLockerAddresses);
            _addTermFinanceRevealOfferLeafs(leafs, termAuctionOfferLockerAddresses);
            _addTermFinanceRedeemTermRepoTokensLeafs(leafs, termRepoServicers);
        }
        setAddress(true, sourceChain, "rawDataDecoderAndSanitizer", rawDataDecoderAndSanitizer);

        // ========================== ITB Reserve ==========================
        ERC20[] memory tokensUsed = new ERC20[](3);
        tokensUsed[0] = getERC20(sourceChain, "SFRXETH");
        tokensUsed[1] = getERC20(sourceChain, "WSTETH");
        tokensUsed[2] = getERC20(sourceChain, "RETH");
        _addLeafsForItbReserve(
            leafs, itbReserveProtocolPositionManager, tokensUsed, "ETHPlus ITB Reserve Protocol Position Manager"
        );

        // ========================== ITB Lido Aave V3 wETH ==========================
        itbDecoderAndSanitizer = itbAaveDecoderAndSanitizer;
        supplyAssets = new ERC20[](1);
        supplyAssets[0] = getERC20(sourceChain, "WETH");
        _addLeafsForItbAaveV3(leafs, itbAaveLidoPositionManager, supplyAssets, "ITB Aave V3 WETH");
        _addLeafsForItbAaveV3(leafs, itbAaveLidoPositionManager2, supplyAssets, "ITB Aave V3 WETH 2");

        // ========================== Native Bridge Leafs ==========================
        ERC20[] memory bridgeAssets = new ERC20[](5);
        bridgeAssets[0] = getERC20(sourceChain, "WETH");
        bridgeAssets[1] = getERC20(sourceChain, "WEETH");
        bridgeAssets[2] = getERC20(sourceChain, "WSTETH");
        bridgeAssets[3] = getERC20(sourceChain, "RETH");
        bridgeAssets[4] = getERC20(sourceChain, "CBETH");
        _addArbitrumNativeBridgeLeafs(leafs, bridgeAssets);

        // ========================== CCIP Bridge Leafs ==========================
        {
            ERC20[] memory ccipBridgeAssets = new ERC20[](1);
            ccipBridgeAssets[0] = getERC20(sourceChain, "WETH");
            ERC20[] memory ccipBridgeFeeAssets = new ERC20[](2);
            ccipBridgeFeeAssets[0] = getERC20(sourceChain, "WETH");
            ccipBridgeFeeAssets[1] = getERC20(sourceChain, "LINK");
            _addCcipBridgeLeafs(leafs, ccipArbitrumChainSelector, ccipBridgeAssets, ccipBridgeFeeAssets);
        }

        // ========================== Standard Bridge ==========================
        {
            ERC20[] memory localTokens = new ERC20[](2);
            localTokens[0] = getERC20(sourceChain, "RETH");
            localTokens[1] = getERC20(sourceChain, "CBETH");
            ERC20[] memory remoteTokens = new ERC20[](2);
            remoteTokens[0] = getERC20(optimism, "RETH");
            remoteTokens[1] = getERC20(optimism, "CBETH");
            _addStandardBridgeLeafs(
                leafs,
                optimism,
                getAddress(optimism, "crossDomainMessenger"),
                getAddress(sourceChain, "optimismResolvedDelegate"),
                getAddress(sourceChain, "optimismStandardBridge"),
                getAddress(sourceChain, "optimismPortal"),
                localTokens,
                remoteTokens
            );

            remoteTokens[0] = getERC20(base, "RETH");
            remoteTokens[1] = getERC20(base, "CBETH");

            _addStandardBridgeLeafs(
                leafs,
                base,
                getAddress(base, "crossDomainMessenger"),
                getAddress(sourceChain, "baseResolvedDelegate"),
                getAddress(sourceChain, "baseStandardBridge"),
                getAddress(sourceChain, "basePortal"),
                localTokens,
                remoteTokens
            );
        }

        // ========================== LayerZero ==========================
        _addLayerZeroLeafs(
            leafs,
            getERC20(sourceChain, "WEETH"),
            getAddress(sourceChain, "EtherFiOFTAdapter"),
            layerZeroOptimismEndpointId
        );
        _addLayerZeroLeafs(
            leafs, getERC20(sourceChain, "WEETH"), getAddress(sourceChain, "EtherFiOFTAdapter"), layerZeroBaseEndpointId
        );

        _addLayerZeroLeafs(
            leafs,
            getERC20(sourceChain, "WEETH"),
            getAddress(sourceChain, "EtherFiOFTAdapter"),
            layerZeroSwellEndpointId
        );

        // ========================== Merkl ==========================
        {
            ERC20[] memory tokensToClaim = new ERC20[](1);
            tokensToClaim[0] = getERC20(sourceChain, "UNI");
            _addMerklLeafs(
                leafs,
                getAddress(sourceChain, "merklDistributor"),
                getAddress(sourceChain, "dev1Address"),
                tokensToClaim
            );
        }

        // ========================== Karak ==========================
        _addKarakLeafs(leafs, getAddress(sourceChain, "vaultSupervisor"), getAddress(sourceChain, "kweETH"));

        // ========================== Treehouse ==========================
        {
            ERC20[] memory routerTokensIn = new ERC20[](1);
            routerTokensIn[0] = getERC20(sourceChain, "WSTETH");
            _addTreehouseLeafs(
                leafs,
                routerTokensIn,
                getAddress(sourceChain, "TreehouseRouter"),
                getAddress(sourceChain, "TreehouseRedemption"),
                getERC20(sourceChain, "tETH"),
                getAddress(sourceChain, "tETH_wstETH_curve_pool"),
                2,
                address(0)
            );
        }

        // ========================== PancakeSwapV3 ==========================
        setAddress(true, sourceChain, "rawDataDecoderAndSanitizer", pancakeSwapDataDecoderAndSanitizer);

        token0 = new address[](8);
        token0[0] = getAddress(sourceChain, "WETH");
        token0[1] = getAddress(sourceChain, "WETH");
        token0[2] = getAddress(sourceChain, "WETH");
        token0[3] = getAddress(sourceChain, "WEETH");
        token0[4] = getAddress(sourceChain, "WEETH");
        token0[5] = getAddress(sourceChain, "WSTETH");
        token0[6] = getAddress(sourceChain, "WETH");
        token0[7] = getAddress(sourceChain, "WETH");

        token1 = new address[](8);
        token1[0] = getAddress(sourceChain, "WEETH");
        token1[1] = getAddress(sourceChain, "WSTETH");
        token1[2] = getAddress(sourceChain, "RETH");
        token1[3] = getAddress(sourceChain, "WSTETH");
        token1[4] = getAddress(sourceChain, "RETH");
        token1[5] = getAddress(sourceChain, "RETH");
        token1[6] = getAddress(sourceChain, "SFRXETH");
        token1[7] = getAddress(sourceChain, "CBETH");

        _addPancakeSwapV3Leafs(leafs, token0, token1);

        // ========================== Reclamation ==========================
        {
            address reclamationDecoder = 0xd7335170816912F9D06e23d23479589ed63b3c33;
            address target = 0x778aC5d0EE062502fADaa2d300a51dE0869f7995;
            _addReclamationLeafs(leafs, target, reclamationDecoder);
            target = 0xC4F5Ee078a1C4DA280330546C29840d45ab32753;
            _addReclamationLeafs(leafs, target, reclamationDecoder);
            target = 0x572F323Aa330B467C356c5a30Bf9A20480F4fD52;
            _addReclamationLeafs(leafs, target, reclamationDecoder);
        }

        // ========================== Hyperlane ==========================
        {
            setAddress(true, mainnet, "rawDataDecoderAndSanitizer", hyperlaneDecoderAndSanitizer);

            uint32 destinationDomain = 1408864445;
            bytes32 recipient = 0x87559103e75eab777571ffabebe0f4f48e729b2a621877aab97084cad3303cbf;
            ERC20 asset = ERC20(0x917ceE801a67f933F2e6b33fC0cD1ED2d5909D88);
            address hyperlaneWeETHsRouter = 0xef899e92DA472E014bE795Ecce948308958E25A2;
            _addLeafsForHyperlane(leafs, destinationDomain, recipient, asset, hyperlaneWeETHsRouter);
        }

        _verifyDecoderImplementsLeafsFunctionSelectors(leafs);

        bytes32[][] memory manageTree = _generateMerkleTree(leafs);

        string memory filePath = "./leafs/MainnetMultiChainLiquidEthStrategistLeafs.json";

        _generateLeafs(filePath, leafs, manageTree[manageTree.length - 1][0], manageTree);
    }

    function _addLeafsForITBPositionManager(
        ManageLeaf[] memory leafs,
        address itbPositionManager,
        ERC20[] memory tokensUsed,
        string memory itbContractName
    ) internal {
        // acceptOwnership
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbPositionManager,
            false,
            "acceptOwnership()",
            new address[](0),
            string.concat("Accept ownership of the ", itbContractName, " contract"),
            itbDecoderAndSanitizer
        );
        for (uint256 i; i < tokensUsed.length; ++i) {
            // Transfer
            leafIndex++;
            leafs[leafIndex] = ManageLeaf(
                address(tokensUsed[i]),
                false,
                "transfer(address,uint256)",
                new address[](1),
                string.concat("Transfer ", tokensUsed[i].symbol(), " to the ", itbContractName, " contract"),
                itbDecoderAndSanitizer
            );
            leafs[leafIndex].argumentAddresses[0] = itbPositionManager;
            // Withdraw
            leafIndex++;
            leafs[leafIndex] = ManageLeaf(
                itbPositionManager,
                false,
                "withdraw(address,uint256)",
                new address[](1),
                string.concat("Withdraw ", tokensUsed[i].symbol(), " from the ", itbContractName, " contract"),
                itbDecoderAndSanitizer
            );
            leafs[leafIndex].argumentAddresses[0] = address(tokensUsed[i]);
            // WithdrawAll
            leafIndex++;
            leafs[leafIndex] = ManageLeaf(
                itbPositionManager,
                false,
                "withdrawAll(address)",
                new address[](1),
                string.concat("Withdraw all ", tokensUsed[i].symbol(), " from the ", itbContractName, " contract"),
                itbDecoderAndSanitizer
            );
            leafs[leafIndex].argumentAddresses[0] = address(tokensUsed[i]);
        }
    }

    function _addLeafsForItbAaveV3(
        ManageLeaf[] memory leafs,
        address itbPositionManager,
        ERC20[] memory tokensUsed,
        string memory itbContractName
    ) internal {
        _addLeafsForITBPositionManager(leafs, itbPositionManager, tokensUsed, itbContractName);
        for (uint256 i; i < tokensUsed.length; ++i) {
            // Deposit
            leafIndex++;
            leafs[leafIndex] = ManageLeaf(
                itbPositionManager,
                false,
                "deposit(address,uint256)",
                new address[](1),
                string.concat("Deposit ", tokensUsed[i].symbol(), " to the ", itbContractName, " contract"),
                itbDecoderAndSanitizer
            );
            leafs[leafIndex].argumentAddresses[0] = address(tokensUsed[i]);
            // Withdraw Supply
            leafIndex++;
            leafs[leafIndex] = ManageLeaf(
                itbPositionManager,
                false,
                "withdrawSupply(address,uint256)",
                new address[](1),
                string.concat("Withdraw ", tokensUsed[i].symbol(), " supply from the ", itbContractName, " contract"),
                itbDecoderAndSanitizer
            );
            leafs[leafIndex].argumentAddresses[0] = address(tokensUsed[i]);
        }

        // Approve Lido v3 Pool to spend tokensUsed.
        for (uint256 i; i < tokensUsed.length; ++i) {
            leafIndex++;
            leafs[leafIndex] = ManageLeaf(
                address(tokensUsed[i]),
                false,
                "approveToken(address,address,uint256)",
                new address[](2),
                string.concat(itbContractName, ": Approve ", tokensUsed[i].symbol(), " to be spent by the Lido v3 Pool"),
                itbDecoderAndSanitizer
            );
            leafs[leafIndex].argumentAddresses[0] = address(tokensUsed[i]);
            leafs[leafIndex].argumentAddresses[1] = getAddress(sourceChain, "v3LidoPool");
        }
    }

    function _addLeafsForItbReserve(
        ManageLeaf[] memory leafs,
        address itbPositionManager,
        ERC20[] memory tokensUsed,
        string memory itbContractName
    ) internal {
        _addLeafsForITBPositionManager(leafs, itbPositionManager, tokensUsed, itbContractName);

        // mint
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbPositionManager,
            false,
            "mint(uint256)",
            new address[](0),
            string.concat("Mint ", itbContractName),
            itbDecoderAndSanitizer
        );

        // redeem
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbPositionManager,
            false,
            "redeem(uint256,uint256[])",
            new address[](0),
            string.concat("Redeem ", itbContractName),
            itbDecoderAndSanitizer
        );

        // redeemCustom
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbPositionManager,
            false,
            "redeemCustom(uint256,uint48[],uint192[],address[],uint256[])",
            new address[](tokensUsed.length),
            string.concat("Redeem custom ", itbContractName),
            itbDecoderAndSanitizer
        );
        for (uint256 i; i < tokensUsed.length; ++i) {
            leafs[leafIndex].argumentAddresses[i] = address(tokensUsed[i]);
        }

        // assemble
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbPositionManager,
            false,
            "assemble(uint256,uint256)",
            new address[](0),
            string.concat("Assemble ", itbContractName),
            itbDecoderAndSanitizer
        );

        // disassemble
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbPositionManager,
            false,
            "disassemble(uint256,uint256[])",
            new address[](0),
            string.concat("Disassemble ", itbContractName),
            itbDecoderAndSanitizer
        );

        // fullDisassemble
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbPositionManager,
            false,
            "fullDisassemble(uint256[])",
            new address[](0),
            string.concat("Full disassemble ", itbContractName),
            itbDecoderAndSanitizer
        );
    }
}
