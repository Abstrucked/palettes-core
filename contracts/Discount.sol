// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {MerkleProof} from"@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Discount {
    // Merkle root for eligible addresses
    bytes32 private merkleRoot;
    uint8 private _discount;

    event MerkleRootUpdated(bytes32 merkleRoot);

    /**
     * @dev Set Merkle root for eligible addresses (onlyOwner).
     * @param _merkleRoot The Merkle root hash
     */
    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(merkleRoot);
    }

    /**
     * @dev Verify if the given address has a discount using a Merkle proof.
     * @param proof The Merkle proof provided by the user.
     * @return True if the proof is valid and the address is eligible for a discount, false otherwise.
     */
    function hasDiscount(bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev Internal function to set the discount percentage.
     * @param d The discount percentage to be set.
     */
    function _setDiscount(uint8 d) internal {
        _discount = d;
    }


    function discount() public view returns(uint8) {
        return _discount;
    }

}
