// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleTree {
    // Merkle root for eligible addresses
    bytes32 private merkleRoot;

    event MerkleRootUpdated(bytes32 merkleRoot);

    /**
     * @dev Set Merkle root for eligible addresses (onlyOwner).
     * @param _merkleRoot The Merkle root hash
     */
    function _setMerkleRoot(bytes32 _merkleRoot) internal virtual {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(merkleRoot);
    }

    /**
     * @dev Verify if the given address has a discount using a Merkle proof.
     * @param proof The Merkle proof provided by the user.
     * @return True if the proof is valid and the address is eligible for a discount, false otherwise.
     */
    function hasDiscount(bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender)))
        );
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
