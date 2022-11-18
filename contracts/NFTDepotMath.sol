// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTDepotMath is Ownable {
   uint256 public marketPercentageCommision = 100; // this is in bips. i.e 1 percent is represented by 10 and 10 by 1000
    uint256 public listingFee = 0;
    uint256 public auctionTimeLimit = 2880; // Set in minutes (2 Days)

    /**
     * @notice Method for setting Listing price
     * @param _newFee new listing feezz
     */

    function setListingFee(uint256 _newFee) external onlyOwner {
        listingFee = _newFee;
    }

    /**
     * @notice Method for setting commision
     * @param _commision new commision fee
     */
    function setpercentageCommision(uint256 _commision) external onlyOwner {
        marketPercentageCommision = _commision;
    }

    /**
     * @notice Method for calculating MarketPlace Commision
     * @param _price selling price of the NFT
     */
    function calculateMarketPlaceCommision(uint256 _price)
        public
        view
        returns (uint256)
    {
        uint256 comission = ((_price / 10000) * marketPercentageCommision);
        return comission;
    }

    /**
     * @notice Method for calculating Seller Profit Commision
     * @param _price selling price of the NFT
     */

    function calculateSellerMoney(uint256 _price)
        public
        view
        returns (uint256)
    {
        uint256 sellerPercentage = 10000 - marketPercentageCommision;
        uint256 sellerMoney = ((_price / 10000) * sellerPercentage);
        return sellerMoney;
    }

    function convertSecToMin(uint256 _time) internal pure returns (uint256) {
        return (_time / 60);
    }

    function convertMinToSec(uint256 _time) internal pure returns (uint256) {
        return (_time * 60);
    }

    function setAuctionTimeLimit(uint256 _time) external onlyOwner {
        auctionTimeLimit = (_time * 60);
    }
}