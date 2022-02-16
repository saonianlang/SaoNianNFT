// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, PullPayment, Ownable {
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 1_00;
    uint256 public constant MINT_PRICE = 0.01 ether;

    Counters.Counter private currentTokenId;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721("NFTSaonian", "saonian") {
        baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmeqPf8CmUBTZZu8Kh6dFtFnuDietsnDczJb3kjEJ8YnJQ";
    }

    function mintTo(address recipient) public payable returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        require(
            msg.value == MINT_PRICE,
            "Transaction value did not equal the mint price"
        );

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Go directly to the corresponding NFT image address 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(address payable payee)
        public
        virtual
        override
        onlyOwner
    {
        super.withdrawPayments(payee);
    }
}
