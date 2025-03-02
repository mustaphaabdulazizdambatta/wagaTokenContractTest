// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenShopUsdt.sol";
import "../src/WagaToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "USDT") {
        _mint(msg.sender, 1_000_000 * 10**6); // 1 million USDT (6 decimals)
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract TokenShopUsdtTest is Test {
    TokenShopUsdt public tokenShop;
    WagaToken public wagaToken;
    MockUSDT public usdt;
    address user = address(0x123);
    address owner = address(this);
    uint256 usdtAmount = 100 * 10**6; // 100 USDT (6 decimals)

    function setUp() public {
        // Deploy WagaToken and USDT
        wagaToken = new WagaToken();
        usdt = new MockUSDT();

        // Deploy TokenShopUsdt with WagaToken and USDT
        tokenShop = new TokenShopUsdt(address(wagaToken), address(usdt), address(0));

        // Assign MINTER_ROLE to TokenShop
        wagaToken.grantMinterRole(address(tokenShop));

        // Fund user with USDT
        usdt.mint(user, 1_000 * 10**6); // 1000 USDT
        vm.startPrank(user);
        usdt.approve(address(tokenShop), usdtAmount);
        vm.stopPrank();
    }

    function testBuyTokensWithUSDT() public {
        uint256 initialWagaBalance = wagaToken.balanceOf(user);
        uint256 initialUSDTBalance = usdt.balanceOf(user);

        // Simulate user buying tokens with USDT
        vm.prank(user);
        tokenShop.buyWithUSDT(usdtAmount);

        // Verify token balance increased
        uint256 finalWagaBalance = wagaToken.balanceOf(user);
        assertGt(finalWagaBalance, initialWagaBalance, "Token balance should increase");

        // Verify USDT balance decreased
        uint256 finalUSDTBalance = usdt.balanceOf(user);
        assertLt(finalUSDTBalance, initialUSDTBalance, "USDT balance should decrease");
    }

    function testFailBuyWithoutApproval() public {
        vm.startPrank(user);
        usdt.approve(address(tokenShop), 0); // Revoke approval
        vm.expectRevert();
        tokenShop.buyWithUSDT(usdtAmount); // Should fail
        vm.stopPrank();
    }

    function testWithdrawUSDT() public {
        // Simulate user buying tokens with USDT
        vm.prank(user);
        tokenShop.buyWithUSDT(usdtAmount);

        uint256 contractUSDTBalance = usdt.balanceOf(address(tokenShop));
        uint256 ownerUSDTBalanceBefore = usdt.balanceOf(owner);

        // Owner withdraws USDT
        vm.prank(owner);
        tokenShop.withdrawUSDT();

        uint256 ownerUSDTBalanceAfter = usdt.balanceOf(owner);
        assertEq(usdt.balanceOf(address(tokenShop)), 0, "Contract should have zero USDT");
        assertEq(ownerUSDTBalanceAfter, ownerUSDTBalanceBefore + contractUSDTBalance, "Owner should receive USDT");
    }
}
