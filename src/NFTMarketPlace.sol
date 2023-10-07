// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/interfaces/IERC721.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

contract ERC721Marketplace is Ownable {
    using ECDSA for bytes32;

    struct Order {
        uint256 orderId;
        address creator;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool active;
    }

    mapping(uint256 => Order) public orders;

    event Name();

    uint256 OrderId;

    function createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        bytes memory _signature,
        uint256 _deadline
    ) external {
        IERC721 token = IERC721(_tokenAddress);
        require(
            token.ownerOf(_tokenId) == msg.sender,
            "You do not own this token"
        );
        bytes32 orderHash = keccak256(
            abi.encode(_tokenAddress, _tokenId, _price)
        );
        require(
            orderHash.toEthSignedMessageHash().recover(_signature) ==
                msg.sender,
            "Invalid signature"
        );
        OrderId++;
        orders[OrderId] = Order({
            orderId: OrderId,
            creator: msg.sender,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            price: _price,
            signature: _signature,
            deadline: _deadline,
            active: true
        });
    }

    function executeOrder(uint256 orderId) external payable {
        Order storage order = orders[orderId];
        require(orders[orderId].creator != address(0), "Invalid order");
        require(orders[orderId].active, "Order is not active");
        require(msg.value == order.price, "Incorrect payment amount");
        require(block.timestamp < order.deadline, "Order expired");
        IERC721 token = IERC721(order.tokenAddress);
        token.safeTransferFrom(order.creator, msg.sender, order.tokenId);
        payable(order.creator).transfer(order.price);
        order.active = false;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
