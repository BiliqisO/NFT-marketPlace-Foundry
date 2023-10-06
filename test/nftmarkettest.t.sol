// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;


import {Test, console2} from "forge-std/Test.sol";
import {VerifySignature} from "../src/Verifysignature.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {MockNFT} from "../src/MockNFT.sol";
 import {ERC721Marketplace } from "../src/NFTMarketPlace.sol";
 import "./Helpers.sol";


contract SignTest is Helpers {
  ERC721Marketplace marketplace;
  MockNFT mockNFT;
  ERC721Marketplace.Order order;

    function setUp() public {
        marketplace = new ERC721Marketplace();
        mockNFT = new MockNFT;

    mockNFT.mint(creator, 1);
    order = ERC721Marketplace.Order({
            orderId:1,
            creator:address(this),
            tokenAddress: address(mockNFT),
            tokenId: 1,
            price:1 ether,
            signature: bytes(""),
            deadline:0,
            active:false
        });  
    }
    function testSignature() public {
     uint privateKey = 3432;
     address User1Pub = vm.addr(privateKey);
     bytes32 messageHash = keccak256( abi.encode( 0x154Adf876Ad1a43bF407aDA8AaefbE0dB2eA92dF, 1, 2e18, 0xa5FFf172361008408da8AcFaF4a9f32012314cA9));
        (uint8 v, bytes32 r, bytes32 s) =  vm.sign(privateKey, messageHash);
        address signer =  ecrecover(messageHash, v, r, s); 
        assertEq(signer, User1Pub );

    }
    function testFailSignature() public {
        uint privateKey = 3432;
        address User1Pub = vm.addr(privateKey);
        bytes32 messageHash = keccak256( abi.encode( 0x154Adf876Ad1a43bF407aDA8AaefbE0dB2eA92dF, 2, 2e18, 0xa5FFf172361008408da8AcFaF4a9f32012314cA9));
        (uint8 v, bytes32 r, bytes32 s) =  vm.sign(privateKey, messageHash);
        address signer =  ecrecover(messageHash, v, r, s); 
        assertTrue(signer != User1Pub );
    }
    function testApproval() public {
        mockNFT.setApprovalForAll(address(marketplace), true);
        assertTrue(mockNFT.isApprovedForAll(owner,address(marketplace)));

    }   
    function testNotOwner() public{
        vm.prank(address(1));
        mockNFT.setApprovalForAll(address(marketplace), true);
        vm.expectRevert(order.tokenAddress, address(1))
    }
    function testPriceNotCorrect()  returns () {
         mockNFT.setApprovalForAll(address(marketplace), true);
         order.price = 0;
        assertFalse(order.price);
    }



     function testExecuteOrder() public {
       
        marketPlace.createOrder(
            orderId:1,
            creator:address(this),
            tokenAddress: address(mockNFT),
            tokenId: 1,
            price:1 ether,
            signature: bytes(""),
            deadline:0,
            active:false
        );

      
        uint256 initialSellerBalance = address(creator).balance;

       
        marketPlace.executeOrder(1);

  
        uint256 finalSellerBalance = address(creator).balance;

        // ERC721Marketplace.Order memory order = marketPlace.orders(1);

        assertEq(order.active, false, "Order should be inactive after execution");
        assertTrue(finalSellerBalance > initialSellerBalance, "Seller's balance should increase");
    }
  }
