// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Template.sol";

contract NFTDepotFactory {
    ERC721Template public nftTemp;

    // struct Data {
    //     address owner;
    //     string uri;
    //     string name;
    //     string symbol;
    //     uint256 totalSupply;
    //     uint256 mintPrice;
    // }

    struct CollectionsbyOwner {
        address[] nftcollections;
    }

    // CollectionsbyOwner collectionsbyowner;

    // owner to collection to collectiondata
    // mapping(address => mapping(address => Data)) public CollectionRecords;

    // owner address to collection
    mapping(address => CollectionsbyOwner) CollectionOwner;

    // modifier isOwner(address _nftCollection) {
    //     Data memory data = CollectionRecords[msg.sender][_nftCollection];
    //     require(data.owner == msg.sender, "You are not the owner");
    //     _;
    // }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply,
        uint256 _mintPrice,
        uint256 _startDate,
        uint256 _expirationDate
    ) public {
        nftTemp = new ERC721Template(_name, _symbol, _uri, _totalSupply, _mintPrice, _startDate, _expirationDate);
        // CollectionRecords[msg.sender][address(nftTemp)] = Data(
        //     msg.sender,
        //     _uri,
        //     _name,
        //     _symbol,
        //     _totalSupply,
        //     _mintPrice
        // );
        CollectionsbyOwner storage tempCollections =  CollectionOwner[msg.sender];
        tempCollections.nftcollections.push(address(nftTemp));

        transferOwner(msg.sender, address(nftTemp));
    }

    function getCollections(address _owner) public view returns(CollectionsbyOwner memory){
        return CollectionOwner[_owner];
    } 

    // function updatePrice(uint256 _newPrice, address _nftCollection)
    //     public
    //     isOwner(_nftCollection)
    // {
    //     CollectionRecords[msg.sender][_nftCollection].mintPrice = _newPrice;
    // }

    // function updateUri(string memory _newUri, address _nftCollection)
    //     public
    //     isOwner(_nftCollection)
    // {
    //     CollectionRecords[msg.sender][_nftCollection].uri = _newUri;
    // }

    function transferOwner(address newOwner, address _nftCollection)
        internal
    {
        // CollectionRecords[msg.sender][_nftCollection].owner = newOwner;
        ERC721Template(_nftCollection).transferOwnership(newOwner);
    }
}
