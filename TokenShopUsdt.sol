// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./OracleLib.sol";
import {WagaToken} from "./WagaToken.sol";

contract TokenShopUsdt is Ownable {
    using OracleLib for AggregatorV3Interface;

    WagaToken public wagaToken;
    IERC20 public usdt;
    AggregatorV3Interface internal priceFeed;
    uint256 public tokenPriceUSD = 200; // 1 token = 2.00 USD (2 decimal places)

    event TokensPurchased(address indexed buyer, uint256 usdtAmount, uint256 tokenAmount);
    event Withdrawn(address indexed owner, uint256 amount);

    constructor(address _wagaToken, address _usdt, address _priceFeed) Ownable(msg.sender) {
        wagaToken = WagaToken(_wagaToken);
        usdt = IERC20(_usdt);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.stalePriceCheckLatestRoundData();
        require(price > 0, "Invalid price data");
        return uint256(price); // USDT/USD price (8 decimals)
    }

    function tokenAmount(uint256 usdtAmount) public view returns (uint256) {
        return (usdtAmount * 100) / tokenPriceUSD; // Adjust for 2 decimal places
    }

    function buyWithUSDT(uint256 usdtAmount) external {
        require(usdtAmount > 0, "Must send USDT");
        uint256 amountToMint = tokenAmount(usdtAmount);
        require(amountToMint > 0, "Not enough USDT to buy tokens");

        // Transfer USDT from buyer to contract
        require(usdt.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");

        // Mint WagaTokens
        wagaToken.mint(msg.sender, amountToMint);
        emit TokensPurchased(msg.sender, usdtAmount, amountToMint);
    }

    function withdrawUSDT() external onlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        require(balance > 0, "No USDT to withdraw");
        require(usdt.transfer(owner(), balance), "USDT withdrawal failed");
        emit Withdrawn(owner(), balance);
    }
}
