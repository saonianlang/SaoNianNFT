// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GrapeMusic is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant maxPerAddressDuringMint = 15; // 地址的最大mint数量
    uint256 public constant auctionMaxSize = 15; // 荷兰拍最大交易数量
    uint256 public constant collectionSize = 30; // 总数量

    // 销售配置结构体
    struct SaleConfig {
        uint32 auctionSaleStartTime; // 荷兰拍开始时间
        uint32 publicSaleStartTime; // 公募开始时间
        uint64 mintlistPrice; // 白名单价格
        uint64 publicPrice; // 公募价格
        uint32 publicSaleKey; // 公募key
    }

    SaleConfig public saleConfig;

    // 白名单列表
    mapping(address => uint256) public allowlist;

    constructor() ERC721A("Grape Music NFT", "GMNFT") {}

    // 验证交易用户
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /// @dev 荷兰拍
    function auctionMint(uint256 quantity) external payable callerIsUser {
        uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
        // 荷兰拍开始时间
        require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "sale has not started yet");
        // 购买个数是否大于拍卖最大个数
        require(totalSupply() + quantity <= auctionMaxSize, "not enough remaining reserved for auction to support desired mint amount");
        // 购买数是否超过个人最大购买
        require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        // 计算总费用
        uint256 totalCost = getAuctionPrice(_saleStartTime) * quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(totalCost);
    }

    /// @dev 白名单
    function allowlistMint() external payable callerIsUser {
        uint256 price = uint256(saleConfig.mintlistPrice);
        // 判断单价是否为空
        require(price != 0, "allowlist sale has not begun yet");
        // 当前地址是否拥有白名单
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        // 购买数量是否大于总数
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(price);
    }

    /// @dev 公开销售
    function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicSaleKey = uint256(config.publicSaleKey);
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        // 验证客户端key
        require(publicSaleKey == callerPublicSaleKey, "called with incorrect public sale key");
        // 验证是否开始公募
        require(isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime), "public sale has not begun yet");
        // 验证购买数是否超过总数
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        // 购买数量是否超过地址最大购买数量
        require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /// @dev 判断是否开始公募
    function isPublicSaleOn(
        uint256 publicPriceWei,
        uint256 publicSaleKey,
        uint256 publicSaleStartTime
    ) public view returns (bool) {
        return publicPriceWei != 0 && publicSaleKey != 0 && block.timestamp >= publicSaleStartTime;
    }

    uint256 public constant AUCTION_START_PRICE = 1 ether; // 荷兰拍最高金额
    uint256 public constant AUCTION_END_PRICE = 0.15 ether; // 荷兰拍最低金额
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes; // 拍卖的时间曲线长度
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes; // 拍卖的时间间隔
    uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL); // 拍卖间隔平均值

    function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256) {
        if (block.timestamp < _saleStartTime) {
            return AUCTION_START_PRICE;
        }
        if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    // 设置销售信息
    function setupSaleInfo(
        uint64 mintlistPrice,
        uint64 publicPrice,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(0, publicSaleStartTime, mintlistPrice, publicPrice, saleConfig.publicSaleKey);
    }

    // 设置拍卖时间
    function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.auctionSaleStartTime = timestamp;
    }

    // 设置公募key
    function setPublicSaleKey(uint32 key) external onlyOwner {
        saleConfig.publicSaleKey = key;
    }

    // 设置白名单
    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // 设置资源地址
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // 提取合约金额
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // 查看地址拥有数量
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}
