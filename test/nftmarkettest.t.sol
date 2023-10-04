// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


import {Test, console2} from "forge-std/Test.sol";
import {VerifySignature} from "../src/Verifysignature.sol";

contract SignTest is Test {
    
    function testSignature() public {
     uint privateKey = 3432;
     address publicKey = vm.addr(privateKey);

     bytes32 messageHash = keccak256( abi.encode( 0x154Adf876Ad1a43bF407aDA8AaefbE0dB2eA92dF, 1, 2e18, 0xa5FFf172361008408da8AcFaF4a9f32012314cA9));
        (uint8 v, bytes32 r, bytes32 s) =  vm.sign(privateKey, messageHash);
        address signer =  ecrecover(messageHash, v, r, s); 
        assertEq(signer, publicKey );

    }
 

}

