// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {MainnetAddresses} from "test/resources/MainnetAddresses.sol";
import {BoringVault} from "src/base/BoringVault.sol";
import {ManagerWithMerkleVerification} from "src/base/Roles/ManagerWithMerkleVerification.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC4626} from "@solmate/tokens/ERC4626.sol";
import {InfraredDecoderAndSanitizer} from "src/base/DecodersAndSanitizers/Protocols/InfraredDecoderAndSanitizer.sol";
import {DecoderCustomTypes} from "src/interfaces/DecoderCustomTypes.sol";
import {RolesAuthority, Authority} from "@solmate/auth/authorities/RolesAuthority.sol";
import {MerkleTreeHelper} from "test/resources/MerkleTreeHelper/MerkleTreeHelper.sol";

import {Test, stdStorage, StdStorage, stdError, console} from "@forge-std/Test.sol";

contract InfraredIntegratonTest is Test, MerkleTreeHelper {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using stdStorage for StdStorage;

    ManagerWithMerkleVerification public manager;
    BoringVault public boringVault;
    address public rawDataDecoderAndSanitizer;
    RolesAuthority public rolesAuthority;

    uint8 public constant MANAGER_ROLE = 1;
    uint8 public constant STRATEGIST_ROLE = 2;
    uint8 public constant MANGER_INTERNAL_ROLE = 3;
    uint8 public constant ADMIN_ROLE = 4;
    uint8 public constant BORING_VAULT_ROLE = 5;
    uint8 public constant BALANCER_VAULT_ROLE = 6;

    function setUp() external {
        setSourceChainName("bartio");
        // Setup forked environment.
        string memory rpcKey = "BARTIO_RPC_URL";
        uint256 blockNumber = 9869258;

        _startFork(rpcKey, blockNumber);

        boringVault = new BoringVault(address(this), "Boring Vault", "BV", 18);

        manager =
            new ManagerWithMerkleVerification(address(this), address(boringVault), getAddress(sourceChain, "vault"));

        rawDataDecoderAndSanitizer = address(new FullInfraredDecoderAndSanitizer());

        setAddress(false, sourceChain, "boringVault", address(boringVault));
        setAddress(false, sourceChain, "rawDataDecoderAndSanitizer", rawDataDecoderAndSanitizer);
        setAddress(false, sourceChain, "manager", address(manager));
        setAddress(false, sourceChain, "managerAddress", address(manager));
        setAddress(false, sourceChain, "accountantAddress", address(1));

        rolesAuthority = new RolesAuthority(address(this), Authority(address(0)));
        boringVault.setAuthority(rolesAuthority);
        manager.setAuthority(rolesAuthority);

        // Setup roles authority.
        rolesAuthority.setRoleCapability(
            MANAGER_ROLE,
            address(boringVault),
            bytes4(keccak256(abi.encodePacked("manage(address,bytes,uint256)"))),
            true
        );
        rolesAuthority.setRoleCapability(
            MANAGER_ROLE,
            address(boringVault),
            bytes4(keccak256(abi.encodePacked("manage(address[],bytes[],uint256[])"))),
            true
        );

        rolesAuthority.setRoleCapability(
            STRATEGIST_ROLE,
            address(manager),
            ManagerWithMerkleVerification.manageVaultWithMerkleVerification.selector,
            true
        );
        rolesAuthority.setRoleCapability(
            MANGER_INTERNAL_ROLE,
            address(manager),
            ManagerWithMerkleVerification.manageVaultWithMerkleVerification.selector,
            true
        );
        rolesAuthority.setRoleCapability(
            ADMIN_ROLE, address(manager), ManagerWithMerkleVerification.setManageRoot.selector, true
        );
        rolesAuthority.setRoleCapability(
            BORING_VAULT_ROLE, address(manager), ManagerWithMerkleVerification.flashLoan.selector, true
        );
        rolesAuthority.setRoleCapability(
            BALANCER_VAULT_ROLE, address(manager), ManagerWithMerkleVerification.receiveFlashLoan.selector, true
        );

        // Grant roles
        rolesAuthority.setUserRole(address(this), STRATEGIST_ROLE, true);
        rolesAuthority.setUserRole(address(manager), MANGER_INTERNAL_ROLE, true);
        rolesAuthority.setUserRole(address(this), ADMIN_ROLE, true);
        rolesAuthority.setUserRole(address(manager), MANAGER_ROLE, true);
        rolesAuthority.setUserRole(address(boringVault), BORING_VAULT_ROLE, true);
        rolesAuthority.setUserRole(getAddress(sourceChain, "vault"), BALANCER_VAULT_ROLE, true);

        // Allow the boring vault to receive ETH.
        rolesAuthority.setPublicCapability(address(boringVault), bytes4(0), true);
    }

    function testInfraredStakingBasic() external {
        deal(getAddress(sourceChain, "kodiak_v1_WBERA_YEET"), address(boringVault), 100e18);

        ManageLeaf[] memory leafs = new ManageLeaf[](8);
        _addInfraredVaultLeafs(leafs, getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault"));

        bytes32[][] memory manageTree = _generateMerkleTree(leafs);

        //_generateTestLeafs(leafs, manageTree);

        manager.setManageRoot(address(this), manageTree[manageTree.length - 1][0]);

        ManageLeaf[] memory manageLeafs = new ManageLeaf[](2);
        manageLeafs[0] = leafs[0]; //approve LP
        manageLeafs[1] = leafs[1]; //stake

        bytes32[][] memory manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        address[] memory targets = new address[](2);
        targets[0] = getAddress(sourceChain, "kodiak_v1_WBERA_YEET");
        targets[1] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        bytes[] memory targetData = new bytes[](2);
        targetData[0] = abi.encodeWithSignature(
            "approve(address,uint256)", getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault"), type(uint256).max
        );
        targetData[1] = abi.encodeWithSignature("stake(uint256)", 100e18);

        address[] memory decodersAndSanitizers = new address[](2);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;
        decodersAndSanitizers[1] = rawDataDecoderAndSanitizer;

        uint256[] memory values = new uint256[](2);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        skip(10 days);

        manageLeafs = new ManageLeaf[](1);
        manageLeafs[0] = leafs[4]; //getReward

        manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        targets = new address[](1);
        targets[0] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        targetData = new bytes[](1);
        targetData[0] = abi.encodeWithSignature("getReward()");

        decodersAndSanitizers = new address[](1);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;

        values = new uint256[](1);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        //check reward balance of boring vault
        uint256 rewardsBalance = getERC20(sourceChain, "iBGT").balanceOf(address(boringVault));
        assertGt(rewardsBalance, 0);

        manageLeafs = new ManageLeaf[](1);
        manageLeafs[0] = leafs[2]; //withdraw

        manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        targets = new address[](1);
        targets[0] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        targetData = new bytes[](1);
        targetData[0] = abi.encodeWithSignature("withdraw(uint256)", 100e18);

        decodersAndSanitizers = new address[](1);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;

        values = new uint256[](1);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        uint256 lpBalance = getERC20(sourceChain, "kodiak_v1_WBERA_YEET").balanceOf(address(boringVault));
        assertEq(lpBalance, 100e18);
    }

    function testInfraredStakingExit() external {
        deal(getAddress(sourceChain, "kodiak_v1_WBERA_YEET"), address(boringVault), 100e18);

        ManageLeaf[] memory leafs = new ManageLeaf[](8);
        _addInfraredVaultLeafs(leafs, getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault"));

        bytes32[][] memory manageTree = _generateMerkleTree(leafs);

        //_generateTestLeafs(leafs, manageTree);

        manager.setManageRoot(address(this), manageTree[manageTree.length - 1][0]);

        ManageLeaf[] memory manageLeafs = new ManageLeaf[](2);
        manageLeafs[0] = leafs[0]; //approve LP
        manageLeafs[1] = leafs[1]; //stake

        bytes32[][] memory manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        address[] memory targets = new address[](2);
        targets[0] = getAddress(sourceChain, "kodiak_v1_WBERA_YEET");
        targets[1] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        bytes[] memory targetData = new bytes[](2);
        targetData[0] = abi.encodeWithSignature(
            "approve(address,uint256)", getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault"), type(uint256).max
        );
        targetData[1] = abi.encodeWithSignature("stake(uint256)", 100e18);

        address[] memory decodersAndSanitizers = new address[](2);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;
        decodersAndSanitizers[1] = rawDataDecoderAndSanitizer;

        uint256[] memory values = new uint256[](2);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        skip(10 days);

        manageLeafs = new ManageLeaf[](1);
        manageLeafs[0] = leafs[5]; //exit (get reward + withdraw)

        manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        targets = new address[](1);
        targets[0] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        targetData = new bytes[](1);
        targetData[0] = abi.encodeWithSignature("exit()");

        decodersAndSanitizers = new address[](1);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;

        values = new uint256[](1);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        uint256 lpBalance = getERC20(sourceChain, "kodiak_v1_WBERA_YEET").balanceOf(address(boringVault));
        assertEq(lpBalance, 100e18);
        uint256 rewardsBalance = getERC20(sourceChain, "iBGT").balanceOf(address(boringVault));
        assertGt(rewardsBalance, 0);
    }

    function testInfraredStakingGetRewardForUser() external {
        deal(getAddress(sourceChain, "kodiak_v1_WBERA_YEET"), address(boringVault), 100e18);

        ManageLeaf[] memory leafs = new ManageLeaf[](8);
        _addInfraredVaultLeafs(leafs, getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault"));

        bytes32[][] memory manageTree = _generateMerkleTree(leafs);

        //_generateTestLeafs(leafs, manageTree);

        manager.setManageRoot(address(this), manageTree[manageTree.length - 1][0]);

        ManageLeaf[] memory manageLeafs = new ManageLeaf[](2);
        manageLeafs[0] = leafs[0]; //approve LP
        manageLeafs[1] = leafs[1]; //stake

        bytes32[][] memory manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        address[] memory targets = new address[](2);
        targets[0] = getAddress(sourceChain, "kodiak_v1_WBERA_YEET");
        targets[1] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        bytes[] memory targetData = new bytes[](2);
        targetData[0] = abi.encodeWithSignature(
            "approve(address,uint256)", getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault"), type(uint256).max
        );
        targetData[1] = abi.encodeWithSignature("stake(uint256)", 100e18);

        address[] memory decodersAndSanitizers = new address[](2);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;
        decodersAndSanitizers[1] = rawDataDecoderAndSanitizer;

        uint256[] memory values = new uint256[](2);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        skip(10 days);

        manageLeafs = new ManageLeaf[](1);
        manageLeafs[0] = leafs[3]; //exit (get reward + withdraw)

        manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        targets = new address[](1);
        targets[0] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        targetData = new bytes[](1);
        targetData[0] = abi.encodeWithSignature("getRewardForUser(address)", address(boringVault));

        decodersAndSanitizers = new address[](1);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;

        values = new uint256[](1);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        uint256 rewardsBalance = getERC20(sourceChain, "iBGT").balanceOf(address(boringVault));
        assertGt(rewardsBalance, 0);

        manageLeafs = new ManageLeaf[](1);
        manageLeafs[0] = leafs[2]; //withdraw

        manageProofs = _getProofsUsingTree(manageLeafs, manageTree);

        targets = new address[](1);
        targets[0] = getAddress(sourceChain, "infrared_kodiak_WBERA_YEET_vault");

        targetData = new bytes[](1);
        targetData[0] = abi.encodeWithSignature("withdraw(uint256)", 100e18);

        decodersAndSanitizers = new address[](1);
        decodersAndSanitizers[0] = rawDataDecoderAndSanitizer;

        values = new uint256[](1);

        manager.manageVaultWithMerkleVerification(manageProofs, decodersAndSanitizers, targets, targetData, values);

        uint256 lpBalance = getERC20(sourceChain, "kodiak_v1_WBERA_YEET").balanceOf(address(boringVault));
        assertEq(lpBalance, 100e18);
    }

    // ========================================= HELPER FUNCTIONS =========================================

    function _startFork(string memory rpcKey, uint256 blockNumber) internal returns (uint256 forkId) {
        forkId = vm.createFork(vm.envString(rpcKey), blockNumber);
        vm.selectFork(forkId);
    }
}

contract FullInfraredDecoderAndSanitizer is InfraredDecoderAndSanitizer {}
