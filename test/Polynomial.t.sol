// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract PolynomialTest is Test {
    IPolynomial public polynomial;

    function setUp() public {
        string memory code = vm.readFile("test/mocks/PolynomialWrappers.huff");
        polynomial = IPolynomial(HuffDeployer.deploy_with_code("util/Polynomial", code));
    }

    function test_Eval() public view {
        // uint256[3] memory result = polynomial.eval(0);
        // console.log(result[0], result[1], result[2]);
        console.log("");
        console.log("L0(0): ", polynomial.eval(0, 0));
        console.log("L0(1): ", polynomial.eval(0, 1));
        console.log("L0(2): ", polynomial.eval(0, 2));

        console.log("");
        console.log("L1(0): ", polynomial.eval(1, 0));
        console.log("L1(1): ", polynomial.eval(1, 1));
        console.log("L1(2): ", polynomial.eval(1, 2));

        console.log("");
        console.log("L2(0): ", polynomial.eval(2, 0));
        console.log("L2(1): ", polynomial.eval(2, 1));
        console.log("L2(2): ", polynomial.eval(2, 2));
    }

    function test_AddEval() public view {
        console.log("L0(0) + L0(0): ", polynomial.addEval(0, 0, 0));
        console.log("L0(0) + L1(0): ", polynomial.addEval(0, 1, 0));
        console.log("L0(0) + L2(0): ", polynomial.addEval(0, 2, 0));
    }

    function test_ScaleEval() public view {
        console.log("L0(0) * 0: ", polynomial.scaleEval(0, 0, 0));
        console.log("L0(0) * 1: ", polynomial.scaleEval(0, 1, 0));
        console.log("L0(0) * 2: ", polynomial.scaleEval(0, 2, 0));
    }
}

interface IPolynomial {
    function eval(uint256 basis, uint256 point) external view returns (uint256 evaluation);

    function addEval(uint256 basis1, uint256 basis2, uint256 point) external view returns (uint256 evaluation);

    function scaleEval(uint256 basis, uint256 scale, uint256 point) external view returns (uint256 evaluation);
}
