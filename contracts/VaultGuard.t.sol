// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {VaultGuard} from "./VaultGuard.sol";
import {Test} from "forge-std/Test.sol";

contract VaultGuardTest is Test {
    VaultGuard vaultGuard;
    address[] nominees;

    function setUp() public {
        vaultGuard = new VaultGuard();
        nominees.push(address(0x1));
        nominees.push(address(0x2));
    }

    function test_CreateWill() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp + 30 days, nominees, "encryptedHash");
        (uint256 deadline, bool triggered, address[] memory nomineesReturned, bytes32 encryptedHash, bytes32 decryptedHash, bool executed) = vaultGuard.getWill(tokenId);
        
        require(deadline == block.timestamp + 30 days, "Deadline should be set correctly");
        require(triggered == false, "Will should not be triggered initially");
        require(nomineesReturned.length == 2, "Nominees should be set correctly");
        require(encryptedHash == "encryptedHash", "Encrypted hash should be set correctly");
        require(decryptedHash == bytes32(0), "Decrypted hash should be empty initially");
        require(executed == false, "Will should not be executed initially");
    }

    function test_Ping() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp + 30 days, nominees, "encryptedHash");
        vaultGuard.ping(tokenId);
        (uint256 deadline, , , , , ) = vaultGuard.getWill(tokenId);
        
        require(deadline == block.timestamp + 30 days + 30 days, "Deadline should be extended by 30 days");
    }

    function test_Trigger() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp, nominees, "encryptedHash");
        vaultGuard.trigger(tokenId);
        ( , bool triggered, , , , ) = vaultGuard.getWill(tokenId);
        
        require(triggered == true, "Will should be triggered after deadline");
    }

    function test_DropShare() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp, nominees, "encryptedHash");
        vaultGuard.trigger(tokenId);
        vaultGuard.dropShare(tokenId, "aesKey", "decryptedHash");
        
        ( , , , , bytes32 decryptedHash, ) = vaultGuard.getWill(tokenId);
        require(decryptedHash == "decryptedHash", "Decrypted hash should be set after dropping share");
    }

    function test_ExecuteWill() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp, nominees, "encryptedHash");
        vaultGuard.trigger(tokenId);
        vaultGuard.dropShare(tokenId, "aesKey", "decryptedHash");
        vaultGuard.executeWill(tokenId);
        
        ( , , , , , bool executed) = vaultGuard.getWill(tokenId);
        require(executed == true, "Will should be executed after execution");
    }

    function test_OnlyOwnerCanPing() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp + 30 days, nominees, "encryptedHash");
        vm.expectRevert("Only owner can ping");
        vaultGuard.ping(tokenId);
    }

    function test_OnlyNomineesCanDropShare() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp, nominees, "encryptedHash");
        vaultGuard.trigger(tokenId);
        vm.expectRevert("Only nominees can drop share");
        vaultGuard.dropShare(tokenId, "aesKey", "decryptedHash");
    }

    function test_OnlyNomineesCanExecute() public {
        uint256 tokenId = vaultGuard.createWill(block.timestamp, nominees, "encryptedHash");
        vaultGuard.trigger(tokenId);
        vaultGuard.dropShare(tokenId, "aesKey", "decryptedHash");
        vm.expectRevert("Only nominees can execute");
        vaultGuard.executeWill(tokenId);
    }
}