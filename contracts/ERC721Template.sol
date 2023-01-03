//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract ERC721Template is ERC721, Ownable {
    // This is for opensea contract name display
    using Strings for uint256;
    uint256 public totalMinted = 0;
    uint256 public mintPrice;
    uint256 public totalMintableSupply;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public startDate;
    uint256 public expirationDate;
    uint256 _tokenIdCounter = 0;

    constructor(
        string memory name,
        string memory symbol,
        string memory _uri,
        uint256 _totalSupply,
        uint256 _mintPrice,
        uint256 _startDate,
        uint256 _expirationDate
    ) ERC721(name, symbol) {
        setBaseURI(_uri);
        totalMintableSupply = _totalSupply;
        mintPrice = _mintPrice;
        startDate = _startDate;
        expirationDate = _expirationDate;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function safeMint() public payable {
        require(block.timestamp >= startDate, "Mint Not Started yet");
        require(block.timestamp >= expirationDate, "Mint Has Ended");
        require(msg.value == mintPrice, "Incorrect Mint Price!");
        require(totalMinted < totalMintableSupply, "Max supply reached");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        totalMinted++;
        _safeMint(msg.sender, tokenId);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function updateStartDate(uint256 _startDate) external onlyOwner {
        startDate = _startDate;
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function updateExpirationDate(uint256 _expirationDate) external onlyOwner {
        expirationDate = _expirationDate;
    }

    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
}
