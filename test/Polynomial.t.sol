// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract PolynomialTest is Test {
    IPolynomial polynomial;
    uint256 constant TOTAL_SUPPLY = 3;
    uint256 constant ORDER = 13;
    bool constant VERBOSE = false;

    function setUp() public {
        string memory code = vm.readFile("test/mocks/PolynomialWrappers.huff");
        polynomial = IPolynomial(HuffDeployer.deploy_with_code("util/Polynomial", code));
    }

    function test_Eval() public {
        for (uint256 basis = 0; basis < TOTAL_SUPPLY; ++basis) {
            VERBOSE ? console.log("") : ();
            for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
                uint256 eval = polynomial.eval(basis, tokenId);
                assertEq(eval, basis == tokenId ? 1 : 0);
                VERBOSE ? console.log("BASIS(", basis, "):", eval) : ();
            }
        }
    }

    // TODO: do more exhaustive tests
    function test_AddEval() public view {
        console.log("L0(0) + L0(0): ", polynomial.addEval(0, 0, 0));
        console.log("L0(0) + L1(0): ", polynomial.addEval(0, 1, 0));
        console.log("L0(0) + L2(0): ", polynomial.addEval(0, 2, 0));
    }

    function test_ScaleEval() public {
        uint256 scale = ORDER / 2; // arbitrary
        for (uint256 basis = 0; basis < TOTAL_SUPPLY; ++basis) {
            VERBOSE ? console.log("") : ();
            for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
                uint256 eval = polynomial.eval(basis, tokenId);
                uint256 scaledEval = polynomial.scaleEval(basis, scale, tokenId);
                assertEq(scaledEval, basis == tokenId ? (eval * scale) % ORDER : 0);
                VERBOSE ? console.log("BASIS(0) *", scale, "=", scaledEval) : ();
            }
        }
    }

    function test_AddScaleStore() public {
        console.log("P(0)", polynomial.evalStore(0));
        console.log("P(1)", polynomial.evalStore(1));
        console.log("P(2)", polynomial.evalStore(2));

        polynomial.addStore(1);

        console.log("P(0) + L1(0)", polynomial.evalStore(0));
        console.log("P(1) + L1(1)", polynomial.evalStore(1));
        console.log("P(2) + L1(2)", polynomial.evalStore(2));

        polynomial.scaleStore(5);

        console.log("5(P(0) + L1(0))", polynomial.evalStore(0));
        console.log("5(P(1) + L1(1))", polynomial.evalStore(1));
        console.log("5(P(2) + L1(2))", polynomial.evalStore(2));
    }
}

interface IPolynomial {
    function eval(uint256 basis, uint256 point) external view returns (uint256 evaluation);

    function addEval(uint256 basis1, uint256 basis2, uint256 point) external view returns (uint256 evaluation);

    function scaleEval(uint256 basis, uint256 scale, uint256 point) external view returns (uint256 evaluation);

    function evalStore(uint256 point) external view returns (uint256 evaluation);

    function addStore(uint256 basis) external;

    function scaleStore(uint256 scale) external;
}
