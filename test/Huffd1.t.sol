// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract Huffd1Test is Test {
    Huffd1 huffd1;
    address constant OWNER = address(0x1); // small address to work for all orders
    uint256 constant TOTAL_SUPPLY = 10;

    /// @dev Set-up to run before each test.
    function setUp() public {
        // TODO: deploy with code where code has the basis?
        huffd1 = Huffd1(HuffDeployer.deploy_with_args("Huffd1", abi.encode(OWNER)));
    }

    /// @dev Should return correct name and symbol.
    function test_NameAndSymbol() public {
        assertEq("Huffd1", huffd1.name());
        assertEq("FFD1", huffd1.symbol());
    }

    /// @dev Should have the correct owner.
    function test_ContractOwnership() public {
        assertEq(OWNER, huffd1.owner());

        address NEW_OWNER = address(0x9);
        vm.prank(OWNER);
        huffd1.setOwner(NEW_OWNER);
        assertEq(NEW_OWNER, huffd1.owner());
    }

    /// @dev Should own tokens at the start.
    function test_Ownership() public {
        assertEq(OWNER, huffd1.ownerOf(0));
        assertEq(OWNER, huffd1.ownerOf(1));
    }

    /// @dev Should transfer correctly.
    function test_Transfer() public {
        assertEq(OWNER, huffd1.ownerOf(0));

        address NEW_OWNER = address(0x9);
        vm.prank(OWNER);
        huffd1.transfer(NEW_OWNER, 0);
        assertEq(huffd1.ownerOf(0), NEW_OWNER);
    }

    /// @dev Should fail to transfer a not-owned token.
    function testFail_Transfer() public {
        vm.prank(address(0x5)); // not an owner
        huffd1.transfer(OWNER, 0);
    }

    /// @dev Should give corect balance.
    function test_BalanceOf() public {
        assertEq(TOTAL_SUPPLY, huffd1.balanceOf(OWNER));
    }
}

// util/Owned.huff
interface Owned {
    function owner() external view returns (address owner);

    function setOwner(address newOwner) external;
}

interface Huffd1 is Owned {
    function name() external view returns (string memory name);

    function symbol() external view returns (string memory symbol);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transfer(address to, uint256 tokenId) external;

    function balanceOf(address owner) external returns (uint256 balance);

    // TODO: approvals?
}
