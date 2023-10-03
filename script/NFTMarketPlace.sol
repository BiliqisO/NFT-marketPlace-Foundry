

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Marketplace is Ownable {
    struct Order {
        address creator;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool executed;
    }

    mapping(uint256 => Order) public orders;

    modifier onlyValidOrder(uint256 orderId) {
        require(orders[orderId].creator != address(0), "Invalid order");
        require(!orders[orderId].executed, "Order already executed");
        _;
    }

    constructor() {}

    function createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        bytes memory _signature,
        uint256 _deadline
    ) external {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "You do not own this token");

        orders[_tokenId] = Order({
            creator: msg.sender,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            price: _price,
            signature: _signature,
            deadline: _deadline,
            executed: false
        });
    }

    function executeOrder(uint256 orderId) external payable onlyValidOrder(orderId) {
        Order storage order = orders[orderId];


        require(msg.value == order.price, "Incorrect payment amount");
        require(block.timestamp < order.deadline, "Order expired");

        IERC721 token = IERC721(order.tokenAddress);
        token.safeTransferFrom(order.creator, msg.sender, order.tokenId);
        payable(order.creator).transfer(order.price);

        order.executed = true;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
