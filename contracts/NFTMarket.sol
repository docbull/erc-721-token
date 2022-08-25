//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarket is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.025 ether;
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // ERC721(string description, string token_symbol)
    constructor() ERC721("NFT Market", "DBW") {
        owner = payable(msg.sender);
    }

    // function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
    //     _tokenIds.increment();
    //     uint256 newTokenId = _tokenIds.current();

    //     _mint(msg.sender, newTokenId);
    //     _setTokenURI(newTokenId, tokenURI);
    //     createTokenItem(newTokenId, price);
    //     return newTokenId;
    // }

    function mintNFT(string memory tokenURI) public payable returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createTokenItem(newTokenId, listingPrice);
        return newTokenId;
    }

    // function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
    //     _tokenIds.increment();
    //     uint256 newItemId = _tokenIds.current();
    //     _mint(recipient, newItemId);
    //     _setTokenURI(newItemId, tokenURI);

    //     return newItemId;
    // }

    
    // function mintPresale(
    //     uint256 amountOfArts,
    //     bytes32 hash,
    //     bytes memory signature
    // ) external payable whenPresaleStarted {
    //     require(initializedYieldToken, "TNI");
    //     require(
    //         checkPresaleEligibility(hash, signature),
    //         "NotEligible"
    //     );
    //     require(totalSupply() < MAX_ARTS, "AllMinted");
    //     require(
    //         amountOfArts <= presaleMaxMint,
    //         "exceeds max"
    //     );
    //     require(
    //         totalSupply() + amountOfArts <= MAX_ARTS,
    //         "exceed supply"
    //     );
    //     require(
    //         _totalClaimed[msg.sender] + amountOfArts <= presaleMaxMint,
    //         "exceed per address"
    //     );
    //     require(amountOfArts > 0, "at least 1");
    //     require(price * amountOfArts == msg.value, "wrong ETH amount");
    //     uint256 _nextTokenId = totalSupply();
    //     for (uint256 i = 0; i < amountOfArts; i++) {
    //         _safeMint(msg.sender, _nextTokenId++);
    //     }
    //     _totalClaimed[msg.sender] += amountOfArts;
    //     yieldToken.updateRewardOnMint(msg.sender);
    //     emit PresaleMint(msg.sender, amountOfArts);
    // }
    // function mint(uint256 amountOfArts) external payable whenPublicSaleStarted {
    //     require(initializedYieldToken, "TNI");
    //     require(totalSupply() < MAX_ARTS, "All tokens have been minted");
    //     require(
    //         amountOfArts <= MAX_PER_MINT,
    //         "exceeds max"
    //     );
    //     require(
    //         totalSupply() + amountOfArts <= MAX_ARTS,
    //         "exceed supply"
    //     );
    //     require(
    //         _totalClaimed[msg.sender] + amountOfArts <= MAX_ARTS_MINT,
    //         "exceed per address"
    //     );
    //     require(amountOfArts > 0, "at least 1");
    //     require(price * amountOfArts == msg.value, "wrong ETH amount");
    //     uint256 _nextTokenId = totalSupply();
    //     for (uint256 i = 0; i < amountOfArts; i++) {
    //         _safeMint(msg.sender, _nextTokenId++);
    //     }
    //     _totalClaimed[msg.sender] += amountOfArts;
    //     yieldToken.updateRewardOnMint(msg.sender);
    //     emit PublicSaleMint(msg.sender, amountOfArts);
    // }

    function updateListingPrice(uint _listingPrice) public payable {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createTokenItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        // require(msg.value == listingPrice, "Price must be equal to listing price");

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    /* allows someone to resell a token they have purchased */
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId) public payable {
        uint price = idToMarketItem[tokenId].price;
        address seller = idToMarketItem[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(seller).transfer(msg.value);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}