// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract Huffd1Test is Test {
    Huffd1 huffd1;

    /// @dev Initial owner, small address works for all orders.
    address constant OWNER = address(0x1);
    /// @dev Number of tokens.
    uint256 constant TOTAL_SUPPLY = 10;

    /// @dev Set-up to run before each test.
    function setUp() public {
        string memory code = vm.readFile("src/test/Huffd1.t.huff");
        huffd1 = Huffd1(HuffDeployer.deploy_with_code_args("Huffd1", code, abi.encode(OWNER)));
    }

    /// @dev Should return correct name and symbol.
    function test_NameAndSymbol() public {
        assertEq("Huffd1", huffd1.name());
        assertEq("FFD1", huffd1.symbol());
    }

    /// @dev Should have the correct owner.
    function test_ContractOwnership() public {
        assertEq(huffd1.owner(), OWNER);

        address NEW_OWNER = address(0x9);
        vm.prank(OWNER);
        huffd1.setOwner(NEW_OWNER);
        assertEq(huffd1.owner(), NEW_OWNER);
    }

    /// @dev Should own tokens at the start.
    function test_InitialTokenOwners() public {
        for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
            assertEq(huffd1.ownerOf(tokenId), OWNER);
        }
    }

    /// @dev Should have no approved tokens at the start.
    function test_InitialTokenApprovals() public {
        address ZERO = address(0);
        for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
            assertEq(huffd1.getApproved(tokenId), ZERO);
        }
    }

    /// @dev Should transfer tokens correctly.
    function test_Transfer() public {
        for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
            // owner --> new owner
            address NEW_OWNER = address(0x9);
            vm.prank(OWNER);
            huffd1.transfer(NEW_OWNER, tokenId);
            assertEq(huffd1.ownerOf(tokenId), NEW_OWNER);

            // new owner -> another new owner
            address NEW_NEW_OWNER = address(0x6);
            vm.prank(NEW_OWNER);
            huffd1.transfer(NEW_NEW_OWNER, tokenId);
            assertEq(huffd1.ownerOf(tokenId), NEW_NEW_OWNER);
        }
    }

    /// @dev Should approve tokens correctly.
    function test_Approve() public {
        for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
            address APPROVAL = address(0x9);
            vm.prank(OWNER);
            huffd1.approve(APPROVAL, tokenId);
            assertEq(huffd1.ownerOf(tokenId), OWNER);
            assertEq(huffd1.getApproved(tokenId), APPROVAL);
        }
    }

    /// @dev Should transfer tokens correctly.
    function test_TransferFrom() public {
        for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
            // owner --> new owner
            address NEW_OWNER = address(0x9);
            vm.prank(OWNER);
            huffd1.transferFrom(OWNER, NEW_OWNER, tokenId);
            assertEq(huffd1.ownerOf(tokenId), NEW_OWNER);

            // new owner -> another new owner
            address NEW_NEW_OWNER = address(0x6);
            vm.prank(NEW_OWNER);
            huffd1.transferFrom(NEW_OWNER, NEW_NEW_OWNER, tokenId);
            assertEq(huffd1.ownerOf(tokenId), NEW_NEW_OWNER);
        }
    }

    /// @dev Should transfer tokens correctly.
    function test_Approve_then_TransferFrom() public {
        for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
            address NEW_OWNER = address(0x9);

            // owner approves new owner
            vm.prank(OWNER);
            huffd1.approve(NEW_OWNER, tokenId);

            // new owner initiates transferFrom
            vm.prank(NEW_OWNER);
            huffd1.transferFrom(OWNER, NEW_OWNER, tokenId);
            assertEq(huffd1.ownerOf(tokenId), NEW_OWNER);

            // TODO: what happens to approval here?
        }
    }

    /// @dev Should fail to transfer a not-owned token.
    function testFail_Transfer_NotOwner() public {
        address NOT_OWNER = address(0x5);
        vm.prank(NOT_OWNER);
        huffd1.transfer(OWNER, 0);
    }

    /// @dev Should fail to transferFrom a not-owned token.
    function testFail_TransferFrom_NotOwner() public {
        address NOT_OWNER = address(0x5);
        vm.prank(NOT_OWNER); // not an owner
        huffd1.transferFrom(NOT_OWNER, NOT_OWNER, 0);
    }

    /// @dev Should not approve a non-owned token.
    function testFail_Approve_NotOwner() public {
        address NOT_OWNER = address(0x5);
        vm.prank(NOT_OWNER);
        huffd1.approve(NOT_OWNER, 0);
    }

    /// @dev Should give corect balance.
    function test_BalanceOf() public {
        assertEq(huffd1.balanceOf(OWNER), TOTAL_SUPPLY);

        // transfer a token
        address NEW_OWNER = address(0x9);
        vm.prank(OWNER);
        huffd1.transfer(NEW_OWNER, 0);
        assertEq(huffd1.ownerOf(0), NEW_OWNER);

        assertEq(huffd1.balanceOf(OWNER), TOTAL_SUPPLY - 1);
        assertEq(huffd1.balanceOf(NEW_OWNER), 1);
    }

    /// @dev Should revert to an invalid function selector.
    function test_InvalidFunction() public {
        (bool success, ) = address(huffd1).call("");
        assertEq(success, false);
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

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address approved);

    function approve(address to, uint256 tokenId) external;
}
