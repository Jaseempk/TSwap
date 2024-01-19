// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Token Swap Contract for ERC20 Tokens
/// @notice This contract allows for the swapping of ERC20 tokens and managing liquidity in a fixed ratio pool.
/// @dev The contract utilizes SafeERC20 for safe ERC20 interactions and implements a 1:1 fixed ratio for liquidity provisions.
contract TSwap is ERC20 {
    using SafeERC20 for IERC20;

    address public tokenAAddress;
    address public tokenBAddress;
    uint256 public constant RATIO = 1;

    // Custom Errors
    error TSwap__InsufficientOutputAmount();
    error TSwap__InsufficientLiquidity();
    error TSwap__InvalidTokenReserve();
    error TSwap__InvalidAddressProvided();

    // Events
    event TokenSwap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed provider, uint256 tokenAAdded, uint256 tokenBAdded);
    event LiquidityRemoved(address indexed provider, uint256 tokenARemoved, uint256 tokenBRemoved);

    /// @notice Constructor for TSwap contract
    /// @param _tokenA Address of Token A
    /// @param _tokenB Address of Token B
    /// @dev The contract is initialized as an ERC20 token representing LP shares.
    constructor(address _tokenA, address _tokenB) ERC20("Token Swap LP", "TS-LP") {
        if (_tokenA == address(0) || _tokenB == address(0)) revert TSwap__InvalidAddressProvided();
        tokenAAddress = _tokenA;
        tokenBAddress = _tokenB;
    }

    /// @notice Add liquidity to the pool in a fixed ratio of 1:1 between Token A and Token B
    /// @param tokenAAmount Amount of Token A to add to the pool
    /// @return liquidity The amount of liquidity tokens (LP tokens) minted to the sender
    /// @dev Emits a LiquidityAdded event upon success
    function addLiquidity(uint256 tokenAAmount) public returns (uint256) {
        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        uint256 tokenBAmount = tokenAAmount * RATIO;
        tokenA.safeTransferFrom(msg.sender, address(this), tokenAAmount);
        tokenB.safeTransferFrom(msg.sender, address(this), tokenBAmount);

        uint256 liquidity = tokenAAmount; // Or any other formula based on your economic model
        _mint(msg.sender, liquidity);

        emit LiquidityAdded(msg.sender, tokenAAmount, tokenBAmount);
        return liquidity;
    }

    /// @notice Remove liquidity from the pool and receive back Token A and Token B in the fixed ratio
    /// @param liquidity Amount of liquidity tokens to burn in exchange for underlying tokens
    /// @return tokenAAmount Amount of Token A returned
    /// @return tokenBAmount Amount of Token B returned
    /// @dev Emits a LiquidityRemoved event upon success
    function removeLiquidity(uint256 liquidity) public returns (uint256, uint256) {
        if (balanceOf(msg.sender) < liquidity) revert TSwap__InsufficientLiquidity();

        uint256 tokenAAmount = liquidity;
        uint256 tokenBAmount = liquidity * RATIO;

        _burn(msg.sender, liquidity);
        IERC20(tokenAAddress).safeTransfer(msg.sender, tokenAAmount);
        IERC20(tokenBAddress).safeTransfer(msg.sender, tokenBAmount);

        emit LiquidityRemoved(msg.sender, tokenAAmount, tokenBAmount);
        return (tokenAAmount, tokenBAmount);
    }

    /// @notice Swap Token A for Token B
    /// @param _tokensToSwap Amount of Token A to swap
    /// @param _minTokensOnSwap Minimum amount of Token B expected to receive
    /// @dev Emits a TokenSwap event upon success
    function tokenAToTokenBSwap(uint256 _tokensToSwap, uint256 _minTokensOnSwap) public {
        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        uint256 tokenAReserve = tokenA.balanceOf(address(this));
        uint256 tokenBReserve = tokenB.balanceOf(address(this));

        uint256 outputTokens = getOutputAmountFromSwap(_tokensToSwap, tokenAReserve, tokenBReserve);
        if (outputTokens < _minTokensOnSwap) revert TSwap__InsufficientOutputAmount();

        tokenA.safeTransferFrom(msg.sender, address(this), _tokensToSwap);
        tokenB.safeTransfer(msg.sender, outputTokens);

        emit TokenSwap(msg.sender, tokenAAddress, tokenBAddress, _tokensToSwap, outputTokens);
    }

    /// @notice Swap Token B for Token A
    /// @param _tokensToSwap Amount of Token B to swap
    /// @param _minTokensOnSwap Minimum amount of Token A expected to receive
    /// @dev Emits a TokenSwap event upon success
    function tokenBToTokenASwap(uint256 _tokensToSwap, uint256 _minTokensOnSwap) public {
        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        uint256 tokenAReserve = tokenA.balanceOf(address(this));
        uint256 tokenBReserve = tokenB.balanceOf(address(this));

        uint256 outputTokens = getOutputAmountFromSwap(_tokensToSwap, tokenBReserve, tokenAReserve);
        if (outputTokens < _minTokensOnSwap) revert TSwap__InsufficientOutputAmount();

        tokenB.safeTransferFrom(msg.sender, address(this), _tokensToSwap);
        tokenA.safeTransfer(msg.sender, outputTokens);

        emit TokenSwap(msg.sender, tokenBAddress, tokenAAddress, _tokensToSwap, outputTokens);
    }
    
    /// @notice Internal function to calculate the output amount of a swap, considering a fee
    /// @param inputTokenAmount Amount of input tokens for the swap
    /// @param inputTokenReserve Current reserve of the input token
    /// @param outputTokenReserve Current reserve of the output token
    /// @return Amount of output tokens after the swap
    function getOutputAmountFromSwap(uint256 inputTokenAmount, uint256 inputTokenReserve, uint256 outputTokenReserve) internal pure returns (uint256) {
        if (inputTokenReserve == 0 || outputTokenReserve == 0) revert TSwap__InvalidTokenReserve();
        uint256 inputAmountWithFee = inputTokenAmount * 997; // 0.3% fee
        uint256 numerator = outputTokenReserve * inputAmountWithFee;
        uint256 denominator = (inputTokenReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }
}
