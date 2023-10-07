// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC721/ERC721.sol";

contract MockNFT is ERC721("MockNFT", "MNFT") {
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return "Okuuurr";
    }

    function mint(address recipient, uint256 tokenId) public payable {
        _mint(recipient, tokenId);
    }
}
