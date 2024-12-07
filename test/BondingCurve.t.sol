// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BondingCurve.sol";

contract BondingCurveTest is Test {
    SuperPull public superPull;
    BondingCurve public bondingCurve;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        // Assign test addresses
        owner = address(this);
        user1 = address(0x200);
        user2 = address(0x300);

        // Deploy SuperPull contract
        superPull = new SuperPull(500 * (10 ** 18));

        // Deploy BondingCurve contract
        bondingCurve = new BondingCurve(0, address(superPull));

        // Transfer tokens to BondingCurve contract for liquidity
        superPull.transfer(address(bondingCurve), 500 * (10 ** 18)); // Transfer 500 MTK
    }

    // Allow the contract to receive ETH
    receive() external payable {}

    /**
     * @notice Test the initial state of the BondingCurve contract
     */
    function testInitialState() public view {
        assertEq(address(bondingCurve.superPull()), address(superPull), "Token address mismatch");
        assertEq(bondingCurve.reserve(), 0, "Initial reserve should be zero");
        assertEq(superPull.balanceOf(address(bondingCurve)), 500 * (10 ** 18), "Initial token reserve mismatch");
    }

    /**
     * @notice Test buying tokens with sufficient ETH
     */
    function testBuyTokens() public {
        uint256 amountToBuy = 50 * (10 ** 18); // 50 MTK
        uint256 cost = bondingCurve.buyPrice(amountToBuy);

        // Simulate user1 buying tokens
        vm.prank(user1);
        vm.deal(user1, cost + 1 ether); // Ensure user1 has enough ETH
        bondingCurve.buy{value: cost}(amountToBuy);

        // Assertions
        assertEq(superPull.balanceOf(user1), amountToBuy, "User1 token balance incorrect");
        assertEq(bondingCurve.reserve(), cost, "Contract reserve incorrect");
        console.log("user1 balance", user1.balance);
        // assertEq(user1.balance, 1 ether - cost, "User1 ETH balance incorrect");
    }

    /**
     * @notice Test buying tokens with insufficient ETH
     */
    function testBuyTokensInsufficientETH() public {
        uint256 amountToBuy = 50 * (10 ** 18); // 50 MTK
        uint256 cost = bondingCurve.buyPrice(amountToBuy);

        // Simulate user1 trying to buy tokens with insufficient ETH
        vm.prank(user1);
        vm.deal(user1, cost - 1 ether); // Less ETH than required

        // Expect revert
        vm.expectRevert("Insufficient ETH sent");
        bondingCurve.buy{value: cost - 1 ether}(amountToBuy);
    }

    /**
     * @notice Test selling tokens with sufficient reserve
     */
    function testSellTokens() public {
        uint256 amountToBuy = 50 * (10 ** 18); // 50 MTK
        uint256 cost = bondingCurve.buyPrice(amountToBuy);

        // User1 buys tokens first
        vm.prank(user1);
        vm.deal(user1, cost);
        bondingCurve.buy{value: cost}(amountToBuy);

        // Calculate expected revenue
        uint256 revenue = bondingCurve.sellPrice(amountToBuy);

        // User1 approves BondingCurve to spend tokens
        vm.prank(user1);
        superPull.approve(address(bondingCurve), amountToBuy);

        // Simulate user1 selling tokens
        vm.prank(user1);
        bondingCurve.sell(amountToBuy);

        // Assertions
        assertEq(superPull.balanceOf(user1), 0, "User1 token balance should be zero after selling");
        assertEq(bondingCurve.reserve(), cost - revenue, "Contract reserve incorrect after selling");
        assertEq(user1.balance, revenue, "User1 ETH balance should have increased by revenue");
    }

    /**
     * @notice Test selling tokens with insufficient reserve
     */
    function testSellTokensInsufficientReserve() public {
        uint256 amountToBuy = 50 * (10 ** 18); // 50 MTK
        uint256 cost = bondingCurve.buyPrice(amountToBuy);

        // User1 buys tokens first
        vm.prank(user1);
        vm.deal(user1, cost);
        bondingCurve.buy{value: cost}(amountToBuy);

        // Calculate expected revenue
        uint256 revenue = bondingCurve.sellPrice(amountToBuy);

        // Owner withdraws enough to deplete reserve below revenue
        uint256 amountToWithdraw = bondingCurve.reserve() - revenue + 1 wei;
        bondingCurve.withdrawReserve(amountToWithdraw);

        // User1 approves BondingCurve to spend tokens
        vm.prank(user1);
        superPull.approve(address(bondingCurve), amountToBuy);

        // Expect revert due to insufficient reserve
        vm.prank(user1);
        vm.expectRevert("Insufficient reserve to pay");
        bondingCurve.sell(amountToBuy);
    }

    /**
     * @notice Test withdrawing reserve by the owner
     */
    function testWithdrawReserve() public {
        uint256 amountToBuy = 50 * (10 ** 18); // 50 MTK
        uint256 cost = bondingCurve.buyPrice(amountToBuy);

        // User1 buys tokens
        vm.prank(user1);
        vm.deal(user1, cost);
        bondingCurve.buy{value: cost}(amountToBuy);

        // Owner withdraws part of the reserve
        uint256 withdrawAmount = cost / 2;
        bondingCurve.withdrawReserve(withdrawAmount);

        // Assertions
        assertEq(bondingCurve.reserve(), cost - withdrawAmount, "Reserve after withdrawal incorrect");
        // assertEq(owner.balance, withdrawAmount, "Owner's ETH balance incorrect after withdrawal");
    }

    /**
     * @notice Test non-owner attempting to withdraw reserve
     */
    function testNonOwnerWithdrawReserve() public {
        uint256 withdrawAmount = 1 ether;

        // Simulate user1 attempting to withdraw reserve
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        bondingCurve.withdrawReserve(withdrawAmount);
    }

    /**
     * @notice Test selling more tokens than total supply
     */
    function testSellMoreThanSupply() public {
        uint256 amountToSell = 600 * (10 ** 18); // Exceeds initial reserve

        // User tries to sell tokens without holding any
        vm.prank(user2);
        vm.expectRevert("Not enough tokens to sell");
        bondingCurve.sell(amountToSell);
    }

    /**
     * @notice Test buying and selling multiple times to ensure reserve consistency
     */
    function testMultipleBuySellOperations() public {
        uint256 firstBuy = 50 * (10 ** 18);
        uint256 firstCost = bondingCurve.buyPrice(firstBuy);

        // User1 buys tokens
        vm.prank(user1);
        vm.deal(user1, firstCost);
        bondingCurve.buy{value: firstCost}(firstBuy);

        // User2 buys tokens
        uint256 secondBuy = 100 * (10 ** 18);
        uint256 secondCost = bondingCurve.buyPrice(secondBuy);
        vm.prank(user2);
        vm.deal(user2, secondCost);
        bondingCurve.buy{value: secondCost}(secondBuy);

        // Calculate expected reserve
        uint256 expectedReserve = firstCost + secondCost;
        assertEq(bondingCurve.reserve(), expectedReserve, "Reserve after multiple buys incorrect");

        // User1 sells firstBuy tokens
        uint256 firstRevenue = bondingCurve.sellPrice(firstBuy);
        vm.startPrank(user1);
        superPull.approve(address(bondingCurve), firstBuy);
        bondingCurve.sell(firstBuy);
        vm.stopPrank();
        expectedReserve -= firstRevenue;
        assertEq(bondingCurve.reserve(), expectedReserve, "Reserve after first sell incorrect");

        // User2 sells firstBuy tokens
        uint256 secondRevenue = bondingCurve.sellPrice(firstBuy);
        vm.startPrank(user2);
        superPull.approve(address(bondingCurve), firstBuy);
        bondingCurve.sell(firstBuy);
        vm.stopPrank();
        expectedReserve -= secondRevenue;
        assertEq(bondingCurve.reserve(), expectedReserve, "Reserve after second sell incorrect");
    }

    /**
     * @notice Test that contract can receive ETH directly
     */
    function testReceiveETH() public {
        uint256 ethSent = 1 ether;

        // Send ETH directly to the contract
        vm.deal(user1, ethSent);
        vm.prank(user1);
        (bool sent,) = address(bondingCurve).call{value: ethSent}("");
        require(sent, "Failed to send ETH");

        // Assertions
        assertEq(bondingCurve.reserve(), ethSent, "Reserve after receiving ETH incorrect");
        assertEq(address(bondingCurve).balance, ethSent, "Contract's ETH balance incorrect");
    }

    /**
     * @notice Test that excess ETH is refunded when buying tokens
     */
    function testBuyTokensWithExcessETH() public {
        uint256 amountToBuy = 50 * (10 ** 18); // 50 MTK
        uint256 cost = bondingCurve.buyPrice(amountToBuy);
        uint256 excess = 1 ether;
        uint256 totalSent = cost + excess;

        // User1 buys tokens with excess ETH
        vm.prank(user1);
        vm.deal(user1, totalSent);
        bondingCurve.buy{value: totalSent}(amountToBuy);

        // Assertions
        assertEq(superPull.balanceOf(user1), amountToBuy, "User1 token balance incorrect");
        assertEq(bondingCurve.reserve(), cost, "Contract reserve incorrect after buy with excess ETH");
        assertEq(user1.balance, 0 + excess, "User1 should have received excess ETH back");
    }
}
