
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract ERC721Marketplace is Ownable {

    using ECDSA for bytes32;
    struct Order {
        uint orderId;
        address creator;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool active;
    }

    mapping(uint256 => Order) public orders;

   uint OrderId;
    function createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        bytes memory _signature,
        uint256 _deadline
    ) external {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "You do not own this token");
        
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

    function executeOrder(uint256 orderId) external payable  {
        Order storage order = orders[orderId];
            bytes32 orderHash = keccak256(abi.encode(order.tokenAddress, order.tokenId, order.price, order.deadline));
        require(orderHash.toEthSignedMessageHash().recover(order.signature) == msg.sender, "Invalid signature");
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
