// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SuperPull} from "./superpull.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {console} from "forge-std/console.sol";

contract BondingCurve is Ownable {
    uint256 public fee;
    SuperPull public superPull;
    uint256 public reserve;
    uint256 public constant INITIAL_PRICE_DIVIDER = 800000;

    event Bought(uint256 amount, uint256 cost);
    event Sold(uint256 amount, uint256 revenue);

    constructor(uint256 _fee, address tokenAddress) Ownable(msg.sender) {
        fee = _fee;
        superPull = SuperPull(tokenAddress);
    }

    function buyPrice(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = superPull.totalSupply();
        uint256 newSupply = currentSupply + amount;
        return ((newSupply * newSupply - currentSupply * currentSupply) / 2) * INITIAL_PRICE_DIVIDER;
    }

    function sellPrice(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = superPull.totalSupply();
        require(amount <= currentSupply, "Not enough tokens to sell");
        uint256 newSupply = currentSupply - amount;
        return ((currentSupply * currentSupply - newSupply * newSupply) / 2) * INITIAL_PRICE_DIVIDER;
    }

    function buy(uint256 amount) external payable {
        uint256 cost = buyPrice(amount);
        require(msg.value >= cost, "Insufficient ETH sent");

        reserve += cost;
        superPull.transfer(msg.sender, amount);

        emit Bought(amount, cost);

        // Refund excess ETH
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function sell(uint256 amount) external {
        uint256 revenue = sellPrice(amount);
        require(address(this).balance >= revenue, "Insufficient reserve to pay");

        reserve -= revenue;
        superPull.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(revenue);

        emit Sold(amount, revenue);
    }

    function withdrawReserve(uint256 amount) external onlyOwner {
        require(amount <= reserve, "Insufficient reserve");
        reserve -= amount;
        payable(owner()).transfer(amount);
    }

    // Fallback to accept ETH
    receive() external payable {
        reserve += msg.value;
    }
}
