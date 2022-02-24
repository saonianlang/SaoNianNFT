// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721A, PullPayment, Ownable {
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant collectionSize = 1_00_00;
    uint256 public constant maxPerWhitelist = 2;

    struct SaleConfig {
        uint32 whitelistSalesTime;
        uint32 publicSaleStartTime;
        uint64 whitelistPrice;
        uint64 publicPrice;
    }

    SaleConfig public saleConfig;

    // Private placement White list
    mapping(address => uint256) public whitelist;

    Counters.Counter private currentTokenId;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721A("GrapeMusic", "GRAPEMUSIC") {
        baseTokenURI = "";
    }

    /// @dev Set sales configuration
    function setSaleConfig(
        uint32 whitelistSalesTime,
        uint32 publicSaleStartTime,
        uint64 whitelistPrice,
        uint64 publicPrice
    ) external onlyOwner {
        saleConfig = SaleConfig(whitelistSalesTime, publicSaleStartTime, whitelistPrice, publicPrice);
    }

    /// @dev Set white list
    function setWhitelist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = numSlots[i];
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whitelistMint() external payable callerIsUser {
        uint256 price = uint256(saleConfig.whitelistPrice);
        require(price != 0, "whitelist sale has not begun yet");
        require(whitelist[msg.sender] > 0, "not eligible for whitelist mint");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        require(numberMinted(msg.sender) + 1 <= maxPerWhitelist, "Ascended can not mint this many");
        whitelist[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(price);
    }

    /// @dev Refund excess amount
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /// @dev Returns the number of tokens minted by `owner`.
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
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
    function withdrawPayments(address payable payee) public virtual override onlyOwner {
        super.withdrawPayments(payee);
    }
}
