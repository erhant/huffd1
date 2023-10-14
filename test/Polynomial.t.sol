// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract PolynomialTest is Test {
    IPolynomial polynomial;
    uint256 constant TOTAL_SUPPLY = 3;
    uint256 constant ORDER = 13;
    bool constant VERBOSE = false;

    function setUp() public {
        string memory code = vm.readFile("src/test/Polynomial.t.huff");
        polynomial = IPolynomial(HuffDeployer.deploy_with_code("util/Polynomial", code));
    }

    function test_Eval() public {
        for (uint256 basis = 0; basis < TOTAL_SUPPLY; ++basis) {
            VERBOSE ? console.log("") : ();
            for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
                uint256 eval = polynomial.eval(basis, tokenId);
                uint256 expected = basis == tokenId ? 1 : 0;
                VERBOSE ? console.log(basis, ":", eval) : ();

                assertEq(eval, expected);
            }
        }
    }

    function test_AddEval() public {
        for (uint256 basis1 = 0; basis1 < TOTAL_SUPPLY; ++basis1) {
            for (uint256 basis2 = 0; basis2 < TOTAL_SUPPLY; ++basis2) {
                VERBOSE ? console.log("") : ();
                for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
                    uint256 eval1 = polynomial.eval(basis1, tokenId);
                    uint256 eval2 = polynomial.eval(basis2, tokenId);
                    uint256 expected = (eval1 + eval2) % ORDER;
                    uint256 addEval = polynomial.addEval(basis1, basis2, tokenId);
                    VERBOSE ? console.log(basis1, basis2, tokenId, addEval) : ();

                    assertEq(addEval, expected);
                }
            }
        }
    }

    function test_ScaleEval() public {
        uint256 scale = ORDER / 2; // arbitrary
        for (uint256 basis = 0; basis < TOTAL_SUPPLY; ++basis) {
            VERBOSE ? console.log("") : ();
            for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
                uint256 eval = polynomial.eval(basis, tokenId);
                uint256 scaledEval = polynomial.scaleEval(basis, scale, tokenId);
                uint256 expected = basis == tokenId ? (eval * scale) % ORDER : 0;
                VERBOSE ? console.log(basis, scale, ":", scaledEval) : ();

                assertEq(scaledEval, expected);
            }
        }
    }

    function test_AddScaleStore() public {
        // stored poly is initially constant zero
        for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
            assertEq(polynomial.evalStore(tokenId), 0);
        }

        uint256 basisToAdd = 0;
        polynomial.addStore(basisToAdd);

        uint256 scale = 4;
        polynomial.scaleStore(scale);

        // now it should be equal to `scale` at the basis that's been added
        for (uint256 basis = 0; basis < TOTAL_SUPPLY; ++basis) {
            VERBOSE ? console.log("") : ();
            for (uint256 tokenId = 0; tokenId < TOTAL_SUPPLY; ++tokenId) {
                uint256 expected = basisToAdd == tokenId ? scale % ORDER : 0;
                VERBOSE ? console.log(basis, tokenId, expected) : ();

                assertEq(polynomial.evalStore(tokenId), expected);
            }
        }
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
