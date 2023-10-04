// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Test, console2} from "forge-std/Test.sol";
import {VerifySignature} from "../src/Verifysignature.sol"; 
import {ERC721Marketplace } from "../src/NFTMarketPlace.sol";
interface IMockNft is IERC721 {
    function safeMint(address to, uint256 tokenId) external;
}
//     interface IERC721 {
//     function balanceOf(address) external view returns (uint256);
//     function deposit() external payable;
// }


contract SignTest is Test {
     using ECDSA for bytes32;
     ERC721Marketplace public marketPlace;
    IMockNft public token;
    address owner;
    address seller;
    address buyer;
    uint256 tokenId = 1;
    uint256 price = 1000000000000000000; // 1 Ether
    uint256 deadline = block.timestamp + 3600; // 1 hour from now
    bytes Signature;
    uint privateKey = 3456;


        ERC721Marketplace.Order  order = marketPlace;

 function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }


    function setUp() public {
    marketPlace = new ERC721Marketplace();
    token = IMockNft(0xAc4D78798804e2463E7785698d51239CfA768DAd);
     owner = vm.addr(privateKey);
        seller = vm.addr(0x123); // Replace with a valid address
        buyer = vm.addr(0x456);  
     token.safeMint(owner, 56);

     console2.logAddress(owner);

        bytes32 ethHash =
            keccak256(
                abi.encodePacked(
                    address(marketPlace),
                    tokenId,
                    price,
                    deadline
                )
            ).toEthSignedMessageHash();

          (uint8 v, bytes32 r, bytes32 s)  =  vm.sign(privateKey , ethHash);
           Signature = getSig(v, r, s);
    }
        
    function test_Approval() public {
        bool allowanceB = token.isApprovedForAll(owner, address(this));
        console2.logBool(allowanceB);
        token.setApprovalForAll(address(this), true);
       bool powner =  token.isApprovedForAll(owner, address(this));
         console2.logBool(powner);
        // address allowanceA = token.getApproved( address(this));
      

    }
   
    function testCreateOrder() public {
        marketPlace.createOrder(
            address(this), // Mock token address
            tokenId,
            price,
            Signature,
            deadline
        );

           order.orders(1);

        assertEq(order.creator, seller, "Creator should be the seller");
        assertEq(order.tokenAddress, address(this), "Token address should match");
       assertEq(order.tokenId, tokenId, "Token ID should match");
       assertEq(order.price, price, "Price should match");
      assertEq(order.signature, Signature, "Signature should match");
     assertEq(order.deadline, deadline, "Deadline should match");
      assertEq(order.active, true, "Order should be active");
    }



    



    function testExecuteOrder() public {
        // Create an order
        marketPlace.createOrder(
            address(this), // Mock token address
            tokenId,
            price,
            Signature,
            deadline
        );

        // Check seller's initial balance
        uint256 initialSellerBalance = address(seller).balance;

        // Execute the order as the buyer
        marketPlace.executeOrder(1);

        // Check seller's final balance
        uint256 finalSellerBalance = address(seller).balance;

        // ERC721Marketplace.Order memory order = marketPlace.orders(1);

        // assertEq(order.active, false, "Order should be inactive after execution");
        assertTrue(finalSellerBalance > initialSellerBalance, "Seller's balance should increase");
    }



}

