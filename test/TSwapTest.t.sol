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
        // Define the amounts of Token A and Token B to be added to the liquidity pool
        uint256 tokenAAmountToAdd = 7e17; // 0.7 Token A
        uint256 tokenBAmountToAdd = tokenAAmountToAdd * RATIO; // Amount of Token B based on the fixed ratio
    
        // Simulate actions from the test user's perspective
        vm.startPrank(testUser);
    
        // Mint the specified amounts of Token A and Token B to the test user
        tokenA.mint(testUser, tokenAAmountToAdd);
        tokenB.mint(testUser, tokenBAmountToAdd);
    
        // Approve the TSwap contract to spend the specified amounts of Token A and Token B on behalf of the test user
        tokenA.approve(address(tSwap), tokenAAmountToAdd);
        tokenB.approve(address(tSwap), tokenBAmountToAdd);
    
        // Add liquidity to the pool and check the resulting LP token balance and supply
        tSwap.addLiquidity(tokenAAmountToAdd);
    
        // Assert that the LP token supply and the test user's LP token balance are correctly updated
        assertEq(tSwap.totalSupply(), tokenAAmountToAdd, "Incorrect LP token supply after addLiquidity");
        assertEq(tSwap.balanceOf(testUser), tokenAAmountToAdd, "Incorrect LP token balance after addLiquidity");
    
        // Stop simulating actions as the test user
        vm.stopPrank();
    }
    
    function testRemoveLiquidity() public {
        // First, add liquidity to set up the initial state for the test
        testAddLiquidity();
    
        // Determine the amount of liquidity to remove, which is the total LP token balance of the test user
        uint256 liquidityToRemove = tSwap.balanceOf(testUser);
    
        // Simulate actions from the test user's perspective
        vm.startPrank(testUser);
    
        // Remove liquidity and receive back Token A and Token B
        (uint256 tokenAAmount, uint256 tokenBAmount) = tSwap.removeLiquidity(liquidityToRemove);
    
        // Assert that the test user received the correct amounts of Token A and Token B after removing liquidity
        assertEq(tokenA.balanceOf(testUser), tokenAAmount, "Incorrect Token A amount received after removeLiquidity");
        assertEq(tokenB.balanceOf(testUser), tokenBAmount, "Incorrect Token B amount received after removeLiquidity");
    
        // Stop simulating actions as the test user
        vm.stopPrank();
    }

    function testTokenAToTokenBSwap() public {
           // First, add liquidity to the pool
        testAddLiquidity();

        uint256 tokensToSwap = 1e17; // 0.1 Token A

        // Calculate expected output using the same formula as in the contract
        uint256 tokenAReserve = tokenA.balanceOf(address(tSwap));
        uint256 tokenBReserve = tokenB.balanceOf(address(tSwap));
        uint256 outputTokens = tSwap.getOutputAmountFromSwap(tokensToSwap, tokenAReserve, tokenBReserve);

        // Use a slightly lower value than the expected output to account for slippage
        uint256 minTokensOnSwap = outputTokens * 95 / 100;

        vm.startPrank(testUser);
        tokenA.mint(testUser, tokensToSwap);
        tokenA.approve(address(tSwap), tokensToSwap);

        // Record initial balances
        uint256 initialBalanceBUser = tokenB.balanceOf(testUser);
        uint256 initialBalanceBPool = tokenB.balanceOf(address(tSwap));
        uint256 initialBalanceAPool = tokenA.balanceOf(address(tSwap));

        // Perform the swap
        tSwap.tokenAToTokenBSwap(tokensToSwap, minTokensOnSwap);

        // Record final balances
        uint256 finalBalanceBUser = tokenB.balanceOf(testUser);
        uint256 finalBalanceBPool = tokenB.balanceOf(address(tSwap));
        uint256 finalBalanceAPool = tokenA.balanceOf(address(tSwap));

        // Assertions
        assertTrue(finalBalanceBUser > initialBalanceBUser, "User should receive Token B");
        assertTrue(finalBalanceBPool < initialBalanceBPool, "Pool should have less Token B");
        assertTrue(finalBalanceAPool > initialBalanceAPool, "Pool should have more Token A");
        vm.stopPrank();
       
    }
    function testTokenBToTokenASwap() public {
        testAddLiquidity();

        uint256 tokensToSwap = 5e17; // 0.5 Token B
        uint256 tokenBReserve = tokenB.balanceOf(address(tSwap));
        uint256 tokenAReserve = tokenA.balanceOf(address(tSwap));
        uint256 outputTokens = tSwap.getOutputAmountFromSwap(tokensToSwap, tokenBReserve, tokenAReserve);
        uint256 minTokensOnSwap = outputTokens * 95 / 100; // Allow for some slippage

        vm.startPrank(testUser);
        tokenB.mint(testUser, tokensToSwap);
        tokenB.approve(address(tSwap), tokensToSwap);

        uint256 initialBalanceAUser = tokenA.balanceOf(testUser);

        tSwap.tokenBToTokenASwap(tokensToSwap, minTokensOnSwap);

        uint256 finalBalanceAUser = tokenA.balanceOf(testUser);

        assertTrue(finalBalanceAUser > initialBalanceAUser, "User should receive Token A");
        vm.stopPrank();
    }

    function testFailAddLiquidityWithInsufficientBalance() public {
        uint256 tokenAAmountToAdd = 2e18; // Attempt to add 2 Token A, but only 1 is available

        vm.startPrank(testUser);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        tSwap.addLiquidity(tokenAAmountToAdd);
        vm.stopPrank();
    }
    function testSwapWithZeroAmount() public {
        testAddLiquidity();

        vm.startPrank(testUser);
        bytes4 customError=bytes4(keccak256("TSwap__InsufficientInputOrOutputAmount()"));
        vm.expectRevert(customError);
        tSwap.tokenAToTokenBSwap(0, 0); //its gonna revert with zero input tokens 
        vm.stopPrank();
    }
    function testStressAddLiquidity() public {
        // Define a large amount for stress testing
        uint256 largeAmount = 1e24; // Equivalent to 1,000,000 Tokens (assuming 18 decimals)

        // Start acting as the test user
        vm.startPrank(testUser);

        // Mint a large amount of both Token A and Token B to the test user
        // This simulates a scenario where the user has a high token balance
        tokenA.mint(testUser, largeAmount);
        tokenB.mint(testUser, largeAmount);

        // Approve the TSwap contract to spend the large amount of both tokens on behalf of the test user
        // Necessary step to allow the contract to transfer these tokens during the liquidity addition
        tokenA.approve(address(tSwap), largeAmount);
        tokenB.approve(address(tSwap), largeAmount);

        // Record the current gas left for analysis
        uint startGas = gasleft();

        // Execute the addLiquidity function with the large amount
        // This is the key operation being stress tested
        tSwap.addLiquidity(largeAmount);

        // Measure the gas left after the operation
        uint endGas = gasleft();

        // Log the gas used for the addLiquidity operation
        // Useful for evaluating the gas efficiency of the contract under high-load conditions
        emit log_named_uint("Gas Used for Stress Test of addLiquidity", startGas - endGas);

        // Stop acting as the test user
        vm.stopPrank();
}


}
