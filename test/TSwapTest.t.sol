// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/TSwap.sol";
import "../src/MockERC20.sol";

contract TSwapTest is Test {
    uint256 constant RATIO=1;
    TSwap private tSwap;
    MockERC20 private tokenA;
    MockERC20 private tokenB;
    address private testUser = address(1);

    function setUp() public {
        // Deploy Mock Tokens
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);

        // Deploy TSwap contract
        tSwap = new TSwap(address(tokenA), address(tokenB));

        // Set up initial token balances for testing
        tokenA.mint(address(this), 1e18); // Mint 1 Token A
        tokenB.mint(address(this), 1e18); // Mint 1 Token B

        // Approve TSwap contract to spend tokens
        tokenA.approve(address(tSwap), 1e18);
        tokenB.approve(address(tSwap), 1e18);
    }

    function testAddLiquidity() public {
        uint256 tokenAAmountToAdd = 1e18; // 1 Token A
        uint256 tokenBAmountToAdd = tokenAAmountToAdd * RATIO ; // Calculated Token B amount

        vm.startPrank(testUser);
        tokenA.mint(testUser, tokenAAmountToAdd);
        tokenB.mint(testUser, tokenBAmountToAdd);
        tokenA.approve(address(tSwap), tokenAAmountToAdd);
        tokenB.approve(address(tSwap), tokenBAmountToAdd);

        tSwap.addLiquidity(tokenAAmountToAdd);

        assertEq(tSwap.totalSupply(), tokenAAmountToAdd, "Incorrect LP token supply after addLiquidity");
        assertEq(tSwap.balanceOf(testUser), tokenAAmountToAdd, "Incorrect LP token balance after addLiquidity");
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        testAddLiquidity();

        uint256 liquidityToRemove = tSwap.balanceOf(testUser);
        vm.startPrank(testUser);
        (uint256 tokenAAmount, uint256 tokenBAmount) = tSwap.removeLiquidity(liquidityToRemove);

        assertEq(tokenA.balanceOf(testUser), tokenAAmount, "Incorrect Token A amount received after removeLiquidity");
        assertEq(tokenB.balanceOf(testUser), tokenBAmount, "Incorrect Token B amount received after removeLiquidity");
        vm.stopPrank();
    }

}
