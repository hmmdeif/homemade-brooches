// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {HomemadeBroochNFT} from "src/HomemadeBroochNFT.sol";
import {FactoryRegistry} from "src/FactoryRegistry.sol";
import {EPAuthority} from "src/proxy/EPAuthority.sol";
import {EPProxyFactory} from "src/proxy/EPProxyFactory.sol";
import {EPProxy} from "src/proxy/EPProxy.sol";
import {Addresses} from "src/Addresses.sol";
import {IPlayerNFT} from "src/interfaces/IPlayerNFT.sol";
import {IPlayers} from "src/interfaces/IPlayers.sol";

contract FactoryRegistryFork is Addresses, Test {
    uint256 public userKey = 1;
    uint256 public ownerKey = 2;
    uint256 public unauthUserKey = 3;
    address public user = vm.addr(userKey);
    address public owner = vm.addr(ownerKey);
    address public unauthUser = vm.addr(unauthUserKey);

    HomemadeBroochNFT public nft;
    FactoryRegistry public registry;
    IPlayerNFT public playerNFT;
    IPlayers public players;

    uint256 private mainnetFork;
    string private MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        vm.rollFork(76378388); // block number
    }

    function _deploy() internal {
        nft = new HomemadeBroochNFT(owner, "");

        vm.prank(owner);
        nft.setTokenUnlock(1, true, 10 ether);

        EPAuthority authority = new EPAuthority(owner);
        EPProxy beaconImpl = new EPProxy();
        UpgradeableBeacon beacon = new UpgradeableBeacon(address(beaconImpl), owner);
        EPProxyFactory proxyFactory = new EPProxyFactory(address(authority), address(beacon));
        FactoryRegistry impl = new FactoryRegistry();
        ERC1967Proxy registryProxy = new ERC1967Proxy(payable(impl), "");
        registry = FactoryRegistry(payable(registryProxy));
        registry.initialize(owner, address(nft), address(proxyFactory));

        vm.prank(owner);
        authority.setAuthority(user, true);
        vm.prank(owner);
        authority.setAuthority(address(registry), true);

        playerNFT = IPlayerNFT(PLAYER_NFT);
        players = IPlayers(PLAYERS);
    }

    function _mintBroochAndCreateProxy() internal {
        vm.deal(user, 21 ether);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        vm.prank(user);
        nft.mintBatch{value: 10 ether}(user, ids, values, "");

        vm.prank(user);
        registry.createProxy();
    }

    function test_MintEstforHero() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(user);
        (, bytes memory data) = address(PLAYER_NFT).call(abi.encodeWithSignature("totalSupply()"));
        uint256 totalSupply = abi.decode(data, (uint256));

        vm.prank(user);
        registry.execute(
            address(proxy), address(PLAYER_NFT), abi.encodeCall(playerNFT.mint, (1, "deif123", "", "", "", false, true))
        );

        (, bytes memory data2) = address(PLAYER_NFT).call(abi.encodeWithSignature("exists(uint256)", totalSupply + 1));
        bool exists = abi.decode(data2, (bool));
        assertEq(exists, true);

        (, bytes memory data3) = address(PLAYER_NFT).call(
            abi.encodeWithSignature("balanceOf(address,uint256)", address(proxy), totalSupply + 1)
        );
        uint256 balance = abi.decode(data3, (uint256));
        assertEq(balance, 1);
    }

    function test_StartAction() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(user);
        registry.execute(
            address(proxy), address(PLAYER_NFT), abi.encodeCall(playerNFT.mint, (1, "deif124", "", "", "", false, true))
        );

        (, bytes memory data) = address(PLAYER_NFT).call(abi.encodeWithSignature("totalSupply()"));
        uint256 totalSupply = abi.decode(data, (uint256));

        IPlayers.QueuedActionInput[] memory queuedActions = new IPlayers.QueuedActionInput[](3);
        queuedActions[0] = IPlayers.QueuedActionInput({
            attire: IPlayers.Attire({head: 0, body: 0, legs: 0, feet: 0, arms: 0, neck: 0, ring: 0, reserved1: 0}),
            regenerateId: 0,
            choiceId: 0,
            rightHandEquipmentTokenId: 0,
            leftHandEquipmentTokenId: 0,
            combatStyle: IPlayers.CombatStyle.NONE,
            actionId: 2500, // thieving child
            timespan: 60 * 60 * 8 // 8 hours
        });
        queuedActions[1] = IPlayers.QueuedActionInput({
            attire: IPlayers.Attire({head: 0, body: 0, legs: 0, feet: 0, arms: 0, neck: 0, ring: 0, reserved1: 0}),
            regenerateId: 0,
            choiceId: 0,
            rightHandEquipmentTokenId: 0,
            leftHandEquipmentTokenId: 0,
            combatStyle: IPlayers.CombatStyle.NONE,
            actionId: 2500, // thieving child
            timespan: 60 * 60 * 8 // 8 hours
        });
        queuedActions[2] = IPlayers.QueuedActionInput({
            attire: IPlayers.Attire({head: 0, body: 0, legs: 0, feet: 0, arms: 0, neck: 0, ring: 0, reserved1: 0}),
            regenerateId: 0,
            choiceId: 0,
            rightHandEquipmentTokenId: 0,
            leftHandEquipmentTokenId: 0,
            combatStyle: IPlayers.CombatStyle.NONE,
            actionId: 2500, // thieving child
            timespan: 60 * 60 * 8 // 8 hours
        });

        vm.prank(user);
        registry.execute(
            address(proxy),
            address(PLAYERS),
            abi.encodeCall(players.startActions, (totalSupply, queuedActions, IPlayers.ActionQueueStatus.NONE))
        );

        (, bytes memory actionQueueData) =
            address(PLAYERS).call(abi.encodeWithSignature("getActionQueue(uint256)", totalSupply));
        IPlayers.QueuedAction[] memory actionQueue = abi.decode(actionQueueData, (IPlayers.QueuedAction[]));
        assertEq(actionQueue.length, 3);
        assertEq(actionQueue[0].actionId, 2500);
        assertEq(actionQueue[1].actionId, 2500);
        assertEq(actionQueue[2].actionId, 2500);
    }

    function test_QueueActionAndExecuteWithKeeper() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(user);
        registry.execute(
            address(proxy), address(PLAYER_NFT), abi.encodeCall(playerNFT.mint, (1, "deif125", "", "", "", false, true))
        );

        (, bytes memory data) = address(PLAYER_NFT).call(abi.encodeWithSignature("totalSupply()"));
        uint256 totalSupply = abi.decode(data, (uint256));

        IPlayers.QueuedActionInput[] memory queuedActions = new IPlayers.QueuedActionInput[](3);
        queuedActions[0] = IPlayers.QueuedActionInput({
            attire: IPlayers.Attire({head: 0, body: 0, legs: 0, feet: 0, arms: 0, neck: 0, ring: 0, reserved1: 0}),
            regenerateId: 0,
            choiceId: 0,
            rightHandEquipmentTokenId: 0,
            leftHandEquipmentTokenId: 0,
            combatStyle: IPlayers.CombatStyle.NONE,
            actionId: 2500, // thieving child
            timespan: 60 * 60 * 8 // 8 hours
        });
        queuedActions[1] = IPlayers.QueuedActionInput({
            attire: IPlayers.Attire({head: 0, body: 0, legs: 0, feet: 0, arms: 0, neck: 0, ring: 0, reserved1: 0}),
            regenerateId: 0,
            choiceId: 0,
            rightHandEquipmentTokenId: 0,
            leftHandEquipmentTokenId: 0,
            combatStyle: IPlayers.CombatStyle.NONE,
            actionId: 2500, // thieving child
            timespan: 60 * 60 * 8 // 8 hours
        });
        queuedActions[2] = IPlayers.QueuedActionInput({
            attire: IPlayers.Attire({head: 0, body: 0, legs: 0, feet: 0, arms: 0, neck: 0, ring: 0, reserved1: 0}),
            regenerateId: 0,
            choiceId: 0,
            rightHandEquipmentTokenId: 0,
            leftHandEquipmentTokenId: 0,
            combatStyle: IPlayers.CombatStyle.NONE,
            actionId: 2500, // thieving child
            timespan: 60 * 60 * 8 // 8 hours
        });

        vm.prank(user);
        registry.setTransaction(
            address(proxy),
            0,
            address(PLAYERS),
            abi.encodeCall(players.startActions, (totalSupply, queuedActions, IPlayers.ActionQueueStatus.NONE))
        );

        vm.prank(unauthUser);
        registry.executeSavedTransactions(address(proxy));

        (, bytes memory actionQueueData) =
            address(PLAYERS).call(abi.encodeWithSignature("getActionQueue(uint256)", totalSupply));
        IPlayers.QueuedAction[] memory actionQueue = abi.decode(actionQueueData, (IPlayers.QueuedAction[]));
        assertEq(actionQueue.length, 3);
        assertEq(actionQueue[0].actionId, 2500);
        assertEq(actionQueue[1].actionId, 2500);
        assertEq(actionQueue[2].actionId, 2500);
    }
}
