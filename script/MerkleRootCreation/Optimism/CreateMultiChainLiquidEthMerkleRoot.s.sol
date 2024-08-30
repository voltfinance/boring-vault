// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC4626} from "@solmate/tokens/ERC4626.sol";
import {MerkleTreeHelper} from "test/resources/MerkleTreeHelper/MerkleTreeHelper.sol";
import "forge-std/Script.sol";

/**
 *  source .env && forge script script/MerkleRootCreation/Optimism/CreateMultiChainLiquidEthMerkleRoot.s.sol:CreateMultiChainLiquidEthMerkleRootScript --rpc-url $OPTIMISM_RPC_URL
 */
contract CreateMultiChainLiquidEthMerkleRootScript is Script, MerkleTreeHelper {
    using FixedPointMathLib for uint256;

    address public boringVault = 0xf0bb20865277aBd641a307eCe5Ee04E79073416C;
    address public rawDataDecoderAndSanitizer = 0x568a4E08909aab6995979dB24B3cdaE00244CeB4;
    address public managerAddress = 0x227975088C28DBBb4b421c6d96781a53578f19a8;
    address public accountantAddress = 0x0d05D94a5F1E76C18fbeB7A13d17C8a314088198;

    address public aerodromeDecoderAndSanitizer = 0x0cD9e50616efdc3a5598e4483e212fe127E08f3C;

    address public itbDecoderAndSanitizer = 0xEEb53299Cb894968109dfa420D69f0C97c835211;
    address public itbGearboxProtocolPositionManager = 0xad5dB17b44506785931dbc49c8857482c3b4F622;

    function setUp() external {}

    /**
     * @notice Uncomment which script you want to run.
     */
    function run() external {
        generateMultiChainLiquidEthStrategistMerkleRoot();
    }

    function generateMultiChainLiquidEthStrategistMerkleRoot() public {
        setSourceChainName(optimism);
        setAddress(false, optimism, "boringVault", boringVault);
        setAddress(false, optimism, "managerAddress", managerAddress);
        setAddress(false, optimism, "accountantAddress", accountantAddress);
        setAddress(false, optimism, "rawDataDecoderAndSanitizer", rawDataDecoderAndSanitizer);

        ManageLeaf[] memory leafs = new ManageLeaf[](256);

        // ========================== Aave V3 ==========================
        ERC20[] memory supplyAssets = new ERC20[](3);
        supplyAssets[0] = getERC20(sourceChain, "WETH");
        supplyAssets[1] = getERC20(sourceChain, "RETH");
        supplyAssets[2] = getERC20(sourceChain, "WSTETH");
        ERC20[] memory borrowAssets = new ERC20[](3);
        borrowAssets[0] = getERC20(sourceChain, "WETH");
        borrowAssets[1] = getERC20(sourceChain, "RETH");
        borrowAssets[2] = getERC20(sourceChain, "WSTETH");
        _addAaveV3Leafs(leafs, supplyAssets, borrowAssets);

        // ========================== Native ==========================
        /**
         * wrap, unwrap
         */
        _addNativeLeafs(leafs);

        // ========================== Gearbox ==========================
        _addGearboxLeafs(leafs, ERC4626(getAddress(sourceChain, "dWETHV3")), getAddress(sourceChain, "sdWETHV3"));

        // ========================== Balancer ==========================
        _addBalancerLeafs(
            leafs, getBytes32(sourceChain, "wstETH_weETH_Id"), getAddress(sourceChain, "wstETH_weETH_Gauge")
        );

        // ========================== Aura ==========================
        _addAuraLeafs(leafs, getAddress(sourceChain, "aura_wstETH_weETH"));

        // ========================== UniswapV3 ==========================
        address[] memory token0 = new address[](5);
        token0[0] = getAddress(sourceChain, "WETH");
        token0[1] = getAddress(sourceChain, "WETH");
        token0[2] = getAddress(sourceChain, "WETH");
        token0[3] = getAddress(sourceChain, "WETH");
        token0[4] = getAddress(sourceChain, "WEETH");

        address[] memory token1 = new address[](5);
        token1[0] = getAddress(sourceChain, "WEETH");
        token1[1] = getAddress(sourceChain, "WSTETH");
        token1[2] = getAddress(sourceChain, "RETH");
        token1[3] = getAddress(sourceChain, "WEETH_OFT");
        token1[4] = getAddress(sourceChain, "WEETH_OFT");

        _addUniswapV3Leafs(leafs, token0, token1);

        // ========================== Fee Claiming ==========================
        /**
         * Claim fees in USDC, DAI, USDT and USDE
         */
        ERC20[] memory feeAssets = new ERC20[](3);
        feeAssets[0] = getERC20(sourceChain, "WETH");
        feeAssets[1] = getERC20(sourceChain, "WEETH");
        feeAssets[2] = getERC20(sourceChain, "WEETH_OFT");
        _addLeafsForFeeClaiming(leafs, feeAssets);

        // ========================== 1inch ==========================
        {
            address[] memory assets = new address[](10);
            SwapKind[] memory kind = new SwapKind[](10);
            assets[0] = getAddress(sourceChain, "WETH");
            kind[0] = SwapKind.BuyAndSell;
            assets[1] = getAddress(sourceChain, "WEETH");
            kind[1] = SwapKind.BuyAndSell;
            assets[2] = getAddress(sourceChain, "WSTETH");
            kind[2] = SwapKind.BuyAndSell;
            assets[3] = getAddress(sourceChain, "WEETH_OFT");
            kind[3] = SwapKind.BuyAndSell;
            assets[4] = getAddress(sourceChain, "CRV");
            kind[4] = SwapKind.Sell;
            assets[5] = getAddress(sourceChain, "AURA");
            kind[5] = SwapKind.Sell;
            assets[6] = getAddress(sourceChain, "BAL");
            kind[6] = SwapKind.Sell;
            assets[7] = getAddress(sourceChain, "RETH");
            kind[7] = SwapKind.BuyAndSell;
            assets[8] = getAddress(sourceChain, "OP");
            kind[8] = SwapKind.Sell;
            assets[9] = getAddress(sourceChain, "UNI");
            kind[9] = SwapKind.Sell;
            _addLeafsFor1InchGeneralSwapping(leafs, assets, kind);
        }

        // ========================== Flashloans ==========================
        _addBalancerFlashloanLeafs(leafs, getAddress(sourceChain, "WETH"));

        // ========================== Compound V3 ==========================
        ERC20[] memory collateralAssets = new ERC20[](2);
        collateralAssets[0] = getERC20(sourceChain, "WSTETH");
        collateralAssets[1] = getERC20(sourceChain, "RETH");
        _addCompoundV3Leafs(
            leafs, collateralAssets, getAddress(sourceChain, "cWETHV3"), getAddress(sourceChain, "cometRewards")
        );

        // ========================== Standard Bridge ==========================
        ERC20[] memory localTokens = new ERC20[](3);
        localTokens[0] = getERC20(sourceChain, "RETH");
        localTokens[1] = getERC20(sourceChain, "CBETH");
        localTokens[2] = getERC20(sourceChain, "WEETH");
        ERC20[] memory remoteTokens = new ERC20[](3);
        remoteTokens[0] = getERC20(mainnet, "RETH");
        remoteTokens[1] = getERC20(mainnet, "CBETH");
        remoteTokens[2] = getERC20(mainnet, "WEETH");
        _addStandardBridgeLeafs(
            leafs,
            mainnet,
            address(0),
            address(0),
            getAddress(sourceChain, "standardBridge"),
            address(0),
            localTokens,
            remoteTokens
        );

        // ========================== Merkl ==========================
        ERC20[] memory tokensToClaim = new ERC20[](2);
        tokensToClaim[0] = getERC20(sourceChain, "UNI");
        tokensToClaim[1] = getERC20(sourceChain, "OP");
        _addMerklLeafs(
            leafs, getAddress(sourceChain, "merklDistributor"), getAddress(sourceChain, "dev1Address"), tokensToClaim
        );

        // ========================== LayerZero ==========================
        _addLayerZeroLeafs(
            leafs, getERC20(sourceChain, "WEETH_OFT"), getAddress(sourceChain, "WEETH_OFT"), layerZeroMainnetEndpointId
        );
        _addLayerZeroLeafs(
            leafs, getERC20(sourceChain, "WEETH_OFT"), getAddress(sourceChain, "WEETH_OFT"), layerZeroBaseEndpointId
        );

        // ========================== Velodrome ==========================
        setAddress(true, sourceChain, "rawDataDecoderAndSanitizer", aerodromeDecoderAndSanitizer);
        token0 = new address[](1);
        token0[0] = getAddress(sourceChain, "WETH");
        token1 = new address[](1);
        token1[0] = getAddress(sourceChain, "WSTETH");
        address[] memory gauges = new address[](1);
        gauges[0] = getAddress(sourceChain, "velodrome_Weth_Wsteth_v3_1_gauge");
        _addVelodromeV3Leafs(
            leafs, token0, token1, getAddress(sourceChain, "velodromeNonFungiblePositionManager"), gauges
        );

        bytes32[][] memory manageTree = _generateMerkleTree(leafs);

        string memory filePath = "./leafs/OptimismMultiChainLiquidEthStrategistLeafs.json";

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

    function _addLeafsForItbGearbox(
        ManageLeaf[] memory leafs,
        address itbPositionManager,
        ERC20 underlying,
        ERC20 diesal,
        address diesalStaking,
        string memory itbContractName
    ) internal {
        ERC20[] memory tokensUsed = new ERC20[](2);
        tokensUsed[0] = underlying;
        tokensUsed[1] = diesal;
        _addLeafsForITBPositionManager(leafs, itbPositionManager, tokensUsed, itbContractName);

        // Approvals
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbGearboxProtocolPositionManager,
            false,
            "approveToken(address,address,uint256)",
            new address[](2),
            string.concat("Approve Gearbox ", diesal.symbol(), " to spend ", underlying.symbol()),
            itbDecoderAndSanitizer
        );
        leafs[leafIndex].argumentAddresses[0] = address(underlying);
        leafs[leafIndex].argumentAddresses[1] = address(diesal);
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbGearboxProtocolPositionManager,
            false,
            "approveToken(address,address,uint256)",
            new address[](2),
            string.concat("Approve Gearbox s", diesal.symbol(), " to spend ", diesal.symbol()),
            itbDecoderAndSanitizer
        );
        leafs[leafIndex].argumentAddresses[0] = address(diesal);
        leafs[leafIndex].argumentAddresses[1] = address(diesalStaking);

        // Deposit
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbGearboxProtocolPositionManager,
            false,
            "deposit(uint256,uint256)",
            new address[](0),
            string.concat("Deposit ", underlying.symbol(), " into Gearbox ", diesal.symbol(), " contract"),
            itbDecoderAndSanitizer
        );

        // Withdraw
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbGearboxProtocolPositionManager,
            false,
            "withdrawSupply(uint256,uint256)",
            new address[](0),
            string.concat("Withdraw ", underlying.symbol(), " from Gearbox ", diesal.symbol(), " contract"),
            itbDecoderAndSanitizer
        );

        // Stake
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbGearboxProtocolPositionManager,
            false,
            "stake(uint256)",
            new address[](0),
            string.concat("Stake ", diesal.symbol(), " into Gearbox s", diesal.symbol(), " contract"),
            itbDecoderAndSanitizer
        );

        // Unstake
        leafIndex++;
        leafs[leafIndex] = ManageLeaf(
            itbGearboxProtocolPositionManager,
            false,
            "unstake(uint256)",
            new address[](0),
            string.concat("Unstake ", diesal.symbol(), " from Gearbox s", diesal.symbol(), " contract"),
            itbDecoderAndSanitizer
        );
    }
}
