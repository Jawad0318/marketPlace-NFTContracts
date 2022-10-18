// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NFTDepotNFT.sol";

contract NFTDepotRoyalties {
    // Struct for saving address and percentage
    struct RoyaltiesData {
        address royaltyReciever;
        uint256 percentageOfRoyalty;
    }

    event RoyalityCreated(
        address NFTCollection,
        address to,
        uint256 percentage
    );
    event RoyaltyPaid(address to, uint256 amount);
    event RoyaltyDataUpdated(address reciever, uint256 Percentage);

    error InvalidAddresses();
    error InvalidPercentageAmount();

    //Mappings for storing records
    mapping(address => RoyaltiesData) public RoyaltyRecord;

    // Checks the owner of the collection
    modifier ownerOfContract(address _addressNFTCollection) {
        NFTDepotNFT nft = NFTDepotNFT(_addressNFTCollection);
        require(nft.owner() == msg.sender, "not the owner of the contract");
        _;
    }

    /** 
    * @notice Method for setting Royalties and reciever address
    * @param _addressNFTCollection is address of the contract
    * @param _royaltyReciever Address of the singular royalty
    * @param _royaltyPercentage Percentage of royalty from to 1000 in BIPs 

     */
    function setRoyalty(
        address _addressNFTCollection,
        address _royaltyReciever,
        uint256 _royaltyPercentage
    ) public ownerOfContract(_addressNFTCollection) {
        if (
            _addressNFTCollection == address(0) ||
            _royaltyReciever == address(0)
        ) {
            revert InvalidAddresses();
        }
        // require(_addressNFTCollection != address(0) || _royaltyReciever != address(0), "Invalid addresses");
        if (_royaltyPercentage < 0 && _royaltyPercentage > 1000) {
            revert InvalidPercentageAmount();
        }
        // require(_royaltyPercentage >= 0 && _royaltyPercentage <= 10, "Invalid Royalty Percentage amount");

        RoyaltyRecord[_addressNFTCollection] = RoyaltiesData(
            _royaltyReciever,
            _royaltyPercentage
        );

        emit RoyalityCreated(
            _addressNFTCollection,
            _royaltyReciever,
            _royaltyPercentage
        );
    }

    /** 
    * @notice Method for Updating Royalties and reciever address
    * @param _addressNFTCollection is address of the contract
    * @param _royaltyReciever Address of the singular royalty
    * @param _royaltyPercentage Percentage of royalty from to 1000 in the form of bips

     */
    function updateRoyalty(
        address _addressNFTCollection,
        address _royaltyReciever,
        uint256 _royaltyPercentage
    ) public ownerOfContract(_addressNFTCollection) {
        if (_royaltyReciever == address(0)) {
            revert InvalidAddresses();
        }
        if (_royaltyPercentage < 0 && _royaltyPercentage > 1000) {
            revert InvalidPercentageAmount();
        }

        // Set new percentage for the contract
        RoyaltyRecord[_addressNFTCollection]
            .percentageOfRoyalty = _royaltyPercentage;

        // Set new reciever address
        RoyaltyRecord[_addressNFTCollection].royaltyReciever = _royaltyReciever;

        emit RoyaltyDataUpdated(_royaltyReciever, _royaltyPercentage);
    }

    /**
     * @notice Method for calculating royalty
     * @param _addressNFTCollection is address of the contract
     * @param _price is the cost selling price of that NFT
     */
    function calculateRoyalties(address _addressNFTCollection, uint256 _price)
        public
        view
        returns (uint256)
    {
        //Stores percentage in a temperorary variable
        uint256 tempPercentage = RoyaltyRecord[_addressNFTCollection]
            .percentageOfRoyalty;
        //Calculate amount of royalties from the given percentage
        uint256 royaltyShare = ((_price / 10000) * tempPercentage);
        //Returns amount
        return royaltyShare;
    }


    function getRoyaltyReciever(address _addressNFTCollection) public view returns (address) {
        return RoyaltyRecord[_addressNFTCollection].royaltyReciever;
    }
}
