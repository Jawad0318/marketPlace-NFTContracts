//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC721Template.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract NFTDepotFactory is Ownable {
    event NFTDeployed(address indexed _nft, string _name, string _symbol, string _localGuid);
    
    mapping(uint => address) private nftTemplates;
    address public minter = address(0x5B30000000000000000000000000000000000000);

    function createNFTTemplate(address _template, uint256 _index) public onlyOwner {
        require(_template != address(0), "Template address cannot be 0");
        require(nftTemplates[_index] == address(0), "Template already exists");

        nftTemplates[_index] = _template;
    }

    function getNFTTemplate(uint256 _index) public view returns (address) {
        return nftTemplates[_index];
    }

    function removeNFTTemplate(uint256 _index) public onlyOwner {
        require(nftTemplates[_index] != address(0), "Template does not exist");

        nftTemplates[_index] = address(0);
    }

    function deployNFT(uint256 _index, string memory _name, string memory _symbol, string memory _localGuid) public {
        require(nftTemplates[_index] != address(0), "Template does not exist");

        address collection = Clones.clone(nftTemplates[_index]);
        // clone ERC721 Template from address
        ERC721Template _nftTemplate = ERC721Template(collection);
        
        _nftTemplate.initialize(msg.sender, _name, _symbol, minter);

        emit NFTDeployed(collection, _name, _symbol, _localGuid);
    }
    
}