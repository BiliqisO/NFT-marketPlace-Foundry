// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {VerifySignature} from "../src/Verifysignature.sol";
import "openzeppelin/interfaces/IERC721.sol";
import {MockNFT} from "../src/MockNFT.sol";
import {ERC721Marketplace} from "../src/NFTMarketPlace.sol";

//  import "./Helpers.sol";

contract SignTest is Test {
    ERC721Marketplace marketplace;
    MockNFT mockNFT;
    address Creator = address(this);
    bytes Signature;
    address buyer;
    uint buyerKey;

    function setUp() public {
        marketplace = new ERC721Marketplace();
        mockNFT = new MockNFT();

        (address _buyer, uint _buyerKey) = makeAddrAndKey("alice");
        buyer = _buyer;
        buyerKey = _buyerKey;
        mockNFT.mint(_buyer, 1);
    }

    function testSignature() public {
        bytes32 ethHash = keccak256(abi.encode(address(mockNFT), 1, 1e18));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerKey, ethHash);
        address signer = ecrecover(ethHash, v, r, s);
        assertEq(signer, buyer);
    }

    function testFailSignature() public {
        uint privateKey = 3432;
        address User1Pub = vm.addr(privateKey);
        bytes32 messageHash = keccak256(
            abi.encode(address(marketplace), 2, 2e18, address(this))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        address signer = ecrecover(messageHash, v, r, s);
        assertFalse(signer == User1Pub);
    }

    function testOwner() public {
        vm.startPrank(buyer);
        bytes32 mHash = keccak256(abi.encode(address(mockNFT), 1, 1e18));
        mHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerKey, mHash);
        Signature = bytes.concat(r, s, bytes1(v));
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.createOrder({
            _tokenAddress: address(mockNFT),
            _tokenId: 1,
            _price: 1 ether,
            _signature: bytes(Signature),
            _deadline: block.timestamp + 200
        });
        vm.stopPrank();
    }

    function testFailNotOwner() public {
        (address test, uint testKey) = makeAddrAndKey("add");
        vm.startPrank(test);
        bytes32 mHash = keccak256(abi.encode(address(mockNFT), 1, 1e18));
        mHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(testKey, mHash);
        Signature = bytes.concat(r, s, bytes1(v));
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.createOrder({
            _tokenAddress: address(mockNFT),
            _tokenId: 1,
            _price: 1 ether,
            _signature: bytes(Signature),
            _deadline: block.timestamp + 3600
        });
        vm.stopPrank();
    }

    function testApproved() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 1 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        uint256 initialSellerBalance = buyer.balance;
        marketplace.executeOrder{value: 1 ether}(1);
        uint256 finalSellerBalance = buyer.balance;
        assertTrue(
            finalSellerBalance > initialSellerBalance,
            "Seller's balance should increase"
        );
    }

    function testFailNotApproved() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 1 ether);
        vm.startPrank(buyerofNFT);
        uint256 initialSellerBalance = buyer.balance;
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.executeOrder{value: 1 ether}(1);
        uint256 finalSellerBalance = buyer.balance;
        assertTrue(
            finalSellerBalance == initialSellerBalance,
            "Seller's balance should not change"
        );
    }

    function testPriceCorrect() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 1 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        uint256 initialSellerBalance = buyer.balance;
        marketplace.executeOrder{value: 1 ether}(1);
        uint256 finalSellerBalance = buyer.balance;
        assertTrue(
            finalSellerBalance > initialSellerBalance,
            "Seller's balance should increase"
        );
    }

    function testFailPriceCorrect() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 1 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        uint256 initialSellerBalance = buyer.balance;
        marketplace.executeOrder{value: 2 ether}(1);
        uint256 finalSellerBalance = buyer.balance;
        assertFalse(
            finalSellerBalance > initialSellerBalance,
            "Seller's balance should not increase"
        );
    }

    // function testFailEarlyTime() public {
    //     address buyerofNFT = makeAddr("buyerofNFT");
    //     vm.startPrank(buyerofNFT);
    //     vm.deal(buyerofNFT, 1 ether);
    //     testOwner();
    // }

    function testFailTimePassed() public {
        testOwner();
        vm.warp(block.timestamp + 250);
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 1 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.executeOrder{value: 1 ether}(1);
        vm.expectRevert("Order expired");
    }

    function testValidOrder() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 1 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.executeOrder{value: 1 ether}(1);
        assertTrue(buyer.balance > 0, "valid order");
    }

    function testFailInvalidOrder() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 1 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.executeOrder{value: 1 ether}(1);
        assertFalse(buyer.balance > 0, "Invalid order");
    }

    function testActiveOrder() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 2 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.executeOrder{value: 1 ether}(1);
        assertTrue(buyer.balance > 0, "Order active");
    }

    function testFailInactiveOrder() public {
        testOwner();
        address buyerofNFT = makeAddr("buyerofNFT");
        vm.deal(buyerofNFT, 2 ether);
        vm.startPrank(buyerofNFT);
        mockNFT.setApprovalForAll(address(marketplace), true);
        marketplace.executeOrder{value: 1 ether}(1);
        marketplace.executeOrder{value: 1 ether}(1);
        vm.expectRevert("Order inactive");
    }
}
