// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultGuard is ERC721, Ownable {
    struct Will {
        uint256 deadline;
        bool triggered;
        address[] nominees;
        bytes32 encryptedHash;
        bytes32 decryptedHash;
        bool executed;
    }

    mapping(uint256 => Will) private _wills;
    uint256 private _nextTokenId;

    event WillTriggered(uint256 indexed tokenId);
    event ShareDropped(uint256 indexed tokenId, bytes aesKey, bytes32 decryptedHash);
    event WillExecuted(uint256 indexed tokenId, address executor);

    constructor() ERC721("VaultGuard", "VG") Ownable(msg.sender) {}

    function createWill(
        uint256 initialDeadline,
        address[] memory nominees,
        bytes32 encryptedHash
    ) external returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _wills[tokenId] = Will({
            deadline: initialDeadline,
            triggered: false,
            nominees: nominees,
            encryptedHash: encryptedHash,
            decryptedHash: bytes32(0),
            executed: false
        });
    }

    function ping(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only owner can ping");
        Will storage will = _wills[tokenId];
        require(!will.triggered, "Will already triggered");
        require(block.timestamp < will.deadline, "Deadline passed");
        will.deadline = block.timestamp + 30 days; // Extend by 30 days
    }

    function trigger(uint256 tokenId) external {
        Will storage will = _wills[tokenId];
        if (block.timestamp > will.deadline && !will.triggered) {
            will.triggered = true;
            emit WillTriggered(tokenId);
        }
    }

    function dropShare(uint256 tokenId, bytes calldata aesKey, bytes32 decryptedHash) external {
        Will storage will = _wills[tokenId];
        require(will.triggered, "Will not triggered");
        require(will.decryptedHash == bytes32(0), "Decrypted hash already set");
        bool isNominee = false;
        for (uint i = 0; i < will.nominees.length; i++) {
            if (will.nominees[i] == msg.sender) {
                isNominee = true;
                break;
            }
        }
        require(isNominee, "Only nominees can drop share");
        will.decryptedHash = decryptedHash;
        emit ShareDropped(tokenId, aesKey, decryptedHash);
    }

    function executeWill(uint256 tokenId) external {
        Will storage will = _wills[tokenId];
        require(will.triggered, "Will not triggered");
        require(will.decryptedHash != bytes32(0), "Decrypted hash not set");
        require(!will.executed, "Will already executed");
        bool isNominee = false;
        for (uint i = 0; i < will.nominees.length; i++) {
            if (will.nominees[i] == msg.sender) {
                isNominee = true;
                break;
            }
        }
        require(isNominee, "Only nominees can execute");
        will.executed = true;
        emit WillExecuted(tokenId, msg.sender);
        // Optional: Transfer NFT to msg.sender or burn
        // _transfer(ownerOf(tokenId), msg.sender, tokenId);
    }

    function getWill(uint256 tokenId) external view returns (
        uint256 deadline,
        bool triggered,
        address[] memory nominees,
        bytes32 encryptedHash,
        bytes32 decryptedHash,
        bool executed
    ) {
        Will storage will = _wills[tokenId];
        return (
            will.deadline,
            will.triggered,
            will.nominees,
            will.encryptedHash,
            will.decryptedHash,
            will.executed
        );
    }
}