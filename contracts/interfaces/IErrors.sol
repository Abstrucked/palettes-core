// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IErrors {
    error MaxSupplyReached();
    error IdNotFound();
    error NotEnoughBalance();
    error ExceedMaxMintable(uint256);
    error IncorrectPrice(uint256);
}
