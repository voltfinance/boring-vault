// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract ArbitrumAddresses {
    // Liquid Ecosystem
    address public deployerAddress = 0x5F2F11ad8656439d5C14d9B351f8b09cDaC2A02d;
    address public dev0Address = 0x0463E60C7cE10e57911AB7bD1667eaa21de3e79b;
    address public dev1Address = 0x2322ba43eFF1542b6A7bAeD35e66099Ea0d12Bd1;
    address public liquidPayoutAddress = 0xA9962a5BfBea6918E958DeE0647E99fD7863b95A;

    // DeFi Ecosystem
    address public ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public uniV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public uniV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniswapV3NonFungiblePositionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public ccipRouter = 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8;
    uint64 public mainnetChainSelector = 5009297550715157269;

    ERC20 public USDC = ERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    ERC20 public USDCe = ERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    ERC20 public WETH = ERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    ERC20 public WBTC = ERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    ERC20 public USDT = ERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    ERC20 public DAI = ERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    ERC20 public WSTETH = ERC20(0x5979D7b546E38E414F7E9822514be443A4800529);
    ERC20 public FRAX = ERC20(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F);
    ERC20 public BAL = ERC20(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    ERC20 public COMP = ERC20(0x354A6dA3fcde098F8389cad84b0182725c6C91dE);
    ERC20 public LINK = ERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);
    ERC20 public rETH = ERC20(0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8);
    ERC20 public RETH = ERC20(0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8);
    ERC20 public cbETH = ERC20(0x1DEBd73E752bEaF79865Fd6446b0c970EaE7732f);
    ERC20 public LUSD = ERC20(0x93b346b6BC2548dA6A1E7d98E9a421B42541425b);
    ERC20 public UNI = ERC20(0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0);
    ERC20 public CRV = ERC20(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978);
    ERC20 public FRXETH = ERC20(0x178412e79c25968a32e89b11f63B33F733770c2A);
    ERC20 public SFRXETH = ERC20(0x95aB45875cFFdba1E5f451B950bC2E42c0053f39);
    ERC20 public ARB = ERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
    ERC20 public WEETH = ERC20(0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe);
    ERC20 public USDE = ERC20(0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34);
    ERC20 public AURA = ERC20(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    ERC20 public PENDLE = ERC20(0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8);
    ERC20 public RSR = ERC20(0xCa5Ca9083702c56b481D1eec86F1776FDbd2e594);

    // Aave V3
    address public v3Pool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    // 1Inch
    address public aggregationRouterV5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    address public oneInchExecutor = 0xE37e799D5077682FA0a244D46E5649F71457BD09;

    address public balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    // Arbitrum native bridging.
    address public arbitrumL2GatewayRouter = 0x5288c571Fd7aD117beA99bF60FE0846C4E84F933;
    address public arbitrumSys = 0x0000000000000000000000000000000000000064;
    address public arbitrumRetryableTx = 0x000000000000000000000000000000000000006E;

    // Pendle
    address public pendleMarketFactory = 0x2FCb47B58350cD377f94d3821e7373Df60bD9Ced;
    address public pendleRouter = 0x888888888889758F76e7103c6CbF23ABbF58F946;
    address public pendleWeETHMarketSeptember = 0xf9F9779d8fF604732EBA9AD345E6A27EF5c2a9d6;

    // Gearbox
    address public dWETHV3 = 0x04419d3509f13054f60d253E0c79491d9E683399;
    address public sdWETHV3 = 0xf3b7994e4dA53E04155057Fd61dc501599d57877;
    address public dUSDCV3 = 0x890A69EF363C9c7BdD5E36eb95Ceb569F63ACbF6;
    address public sdUSDCV3 = 0xD0181a36B0566a8645B7eECFf2148adE7Ecf2BE9;
    address public dUSDCeV3 = 0xa76c604145D7394DEc36C49Af494C144Ff327861;
    address public sdUSDCeV3 = 0x608F9e2E8933Ce6b39A8CddBc34a1e3E8D21cE75;

    // Uniswap V3 pools
    address public wstETH_wETH_01 = 0x35218a1cbaC5Bbc3E57fd9Bd38219D37571b3537;
    address public wstETH_wETH_05 = 0xb93F8a075509e71325c1c2fc8FA6a75f2d536A13;
    address public PENDLE_wETH_30 = 0xdbaeB7f0DFe3a0AAFD798CCECB5b22E708f7852c;
    address public wETH_weETH_30 = 0xA169d1aB5c948555954D38700a6cDAA7A4E0c3A0;
    address public wETH_weETH_05 = 0xd90660A0b8Ad757e7C1d660CE633776a0862b087;
    address public wETH_weETH_01 = 0x14353445c8329Df76e6f15e9EAD18fA2D45A8BB6;

    // Chainlink feeds
    address public weETH_ETH_ExchangeRate = 0x20bAe7e1De9c596f5F7615aeaa1342Ba99294e12;

    // Fluid fTokens
    address public fUSDC = 0x1A996cb54bb95462040408C06122D45D6Cdb6096;
    address public fUSDT = 0x4A03F37e7d3fC243e3f99341d36f4b829BEe5E03;
    address public fWETH = 0x45Df0656F8aDf017590009d2f1898eeca4F0a205;
    address public fWSTETH = 0x66C25Cd75EBdAA7E04816F643d8E46cecd3183c9;
}
