// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/WagaToken.sol";

contract WagaTokenTest is Test {
    WagaToken public wagaToken;
    address public deployer = address(1);
    address public minter = address(2);
    address public user = address(3);
    
    function setUp() public {
        vm.prank(deployer);
        wagaToken = new WagaToken();
    }

    function testDeployment() public {
        assertEq(wagaToken.name(), "WagaToken");
        assertEq(wagaToken.symbol(), "WAGA");
        assertEq(wagaToken.decimals(), 18);
    }

    function testGrantMinterRole() public {
        vm.prank(deployer);
        wagaToken.grantMinterRole(minter);
        assertTrue(wagaToken.hasRole(wagaToken.MINTER_ROLE(), minter));
    }

    function testMintTokens() public {
        vm.startPrank(deployer);
        wagaToken.grantMinterRole(minter);
        vm.stopPrank();
        
        vm.prank(minter);
        wagaToken.mint(user, 1000 ether);
        assertEq(wagaToken.balanceOf(user), 1000 ether);
    }

    function testFailMintWithoutMinterRole() public {
        vm.prank(user);
        wagaToken.mint(user, 1000 ether);
    }

    function testMaxSupplyEnforcement() public {
    vm.startPrank(deployer);
    wagaToken.grantMinterRole(minter);
    vm.stopPrank();

    vm.startPrank(minter);
    wagaToken.mint(user, wagaToken.MAX_SUPPLY());
    vm.expectRevert("WagaToken: Max supply exceeded");
    wagaToken.mint(user, 1 ether);
    vm.stopPrank();
}

}
