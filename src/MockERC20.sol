// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Mock ERC20 Token for Testing Purposes
contract MockERC20 is ERC20 {
    uint8 private _tokenDecimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _tokenDecimals = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return _tokenDecimals;
    }

    /// @notice Function to mint tokens
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /// @notice Function to burn tokens
    /// @param from Address from which tokens will be burned
    /// @param amount Amount of tokens to burn
    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
