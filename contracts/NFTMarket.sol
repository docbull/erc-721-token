//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarket is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable creator;
    // uint256 mintingFee = 0.025 ether;

    mapping(uint256 => MarketItem) private getItemById;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool listed;
    }

    event MarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool listed
    );
    
    // ERC721(string description, string token_symbol)
    constructor() ERC721("GRY NFT Market", "GRY") {}

    function mintNFT(string memory tokenURI) public payable returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createNFTItem(newTokenId);
        return newTokenId;
    }

    function createNFTItem(uint256 tokenId) private {
        // require(price > 0, "Price must be at least 1 wei");
        uint256 price = 0 ether;
        getItemById[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(msg.sender),
            price,
            false
        );
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            msg.sender,
            price,
            false
        );
    }
    
    // priceOf returns price of selected item (i.e., token)
    function priceOf(uint256 tokenId) public view returns (uint256) {
        return getItemById[tokenId].price;
    }

    // listItem lists the item (i.e., token) to marketplace with token ID and price
    function listItem(uint256 tokenId, uint256 price) public payable {
        address payable itemOwner = getItemById[tokenId].owner;
        require(itemOwner == msg.sender, "Only item owner can list the item");
        require(price > 0, "Price must be at least 1 wei");
        getItemById[tokenId].price = price;
        getItemById[tokenId].listed = true;
        getItemById[tokenId].seller = itemOwner;
    }

    // updatePrice updates listed item with token ID
    function updatePrice(uint256 tokenId, uint256 price) public payable {
        address payable itemOwner = getItemById[tokenId].owner;
        require(itemOwner == msg.sender, "Only item owner can list the item");
        require(getItemById[tokenId].listed == true, "Only the listed item could be ran");
        require(price > 0, "Price must be at least 1 wei");
        getItemById[tokenId].price = price;
    }

    // buyItem requests to pay ether to the buyer for purchasing item, and it transfers the item
    // from seller to buyer if the buyer successfully payed the price
    function buyItem(uint256 tokenId) public payable {
        uint price = getItemById[tokenId].price;
        address seller = getItemById[tokenId].seller;
        bool isListed = getItemById[tokenId].listed;
        require(isListed == true, "You can buy listed item");
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        payable(seller).transfer(msg.value);
        _transfer(getItemById[tokenId].owner, msg.sender, tokenId);
        getItemById[tokenId].seller = payable(getItemById[tokenId].owner);
        getItemById[tokenId].owner = payable(msg.sender);
        getItemById[tokenId].price = 0;
        getItemById[tokenId].listed = false;
    }
}