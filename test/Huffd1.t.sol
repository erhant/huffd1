// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract Huffd1Test is Test {
    Huffd1 huffd1;
    address constant OWNER = address(0x1); // small address to work for all orders

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
    function test_Owned() public {
        assertEq(OWNER, huffd1.owner());

        address NEW_OWNER = address(0x2);
        vm.prank(OWNER);
        huffd1.setOwner(NEW_OWNER);
        assertEq(NEW_OWNER, huffd1.owner());
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
}
