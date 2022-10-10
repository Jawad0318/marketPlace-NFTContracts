// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NFTDepotNFT.sol";
import "./NFTDepotMath.sol";

import "hardhat/console.sol"; //For debugging only

error InvalidAuction();
error AuctionClosed();
error ContractCall();
error InvalidBidPrice();
error OwnerCannotBid();
error AuctionStillOpen();
error InvalidAuctionCreator();
error AuctionHasBids();
error NoBidsToClaim();

// This was named MarketPlace before.
contract NFTDepotAuctions is IERC721Receiver, ReentrancyGuard, NFTDepotMath {
    // Index of auctions
    uint256 public index = 0;
    // Structure to define auction properties
    struct Auction {
        uint256 index; // Auction Index
        address addressNFTCollection; // Address of the ERC721 NFT Collection contract
        uint256 nftId; // NFT Id
        address payable creator; // Creator of the Auction
        address payable currentBidOwner; // Address of the highest bider
        uint256 currentBidPrice; // Current highest bid for the auction
        uint256 endAuction; // Timestamp for the end day&time of the auction
        uint256 bidCount; // Number of bid placed on the auction
    }

    // Public event to notify that a new auction has been created
    event NewAuction(
        uint256 index,
        address addressNFTCollection,
        uint256 nftId,
        address mintedBy,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 endAuction,
        uint256 bidCount
    );

    // Array will store all auctions
    Auction[] public allAuctions;

    // Public event to notify that a new bid has been placed
    event NewBidOnAuction(uint256 auctionIndex, uint256 newBid);

    // Public event to notif that winner of an
    // auction claim for his reward
    event NFTClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that the creator of
    // an auction claimed for his money
    event TokensClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that an NFT has been refunded to the
    // creator of an auction
    event NFTRefunded(uint256 auctionIndex, uint256 nftId, address claimedBy);

    /**
     * Check if an auction is open
     * @param _auctionIndex Index of the auction
     */
    function isOpen(uint256 _auctionIndex) public view returns (bool) {
        Auction storage auction = allAuctions[_auctionIndex];
        if (block.timestamp >= auction.endAuction) return false;
        return true;
    }

    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
     */
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    // Auction features.

    /**
     * Place new bid on a specific auction
     * @param _auctionIndex Index of auction
     */
    function bid(uint256 _auctionIndex)
        external
        payable
        nonReentrant
        returns (bool)
    {
        // require(_auctionIndex < allAuctions.length, "Invalid auction index");
        if (_auctionIndex > allAuctions.length) {
            revert InvalidAuction();
        }

        Auction storage auction = allAuctions[_auctionIndex];

        // check if auction is still open
        // require(isOpen(_auctionIndex), "Auction is not open");
        if (!isOpen(_auctionIndex)) {
            revert AuctionClosed();
        }

        // Somewhat prevents contract calls
        // require(!isContract(msg.sender), "Cannot be called by a contract");
        // Need to confirm
        if (isContract(msg.sender)) {
            revert ContractCall();
        }

        // check if new bid price is higher than the current one
        // require(
        //     msg.value > auction.currentBidPrice,
        //     "New bid price must be higher than the current bid"
        // );
        if (msg.value <= auction.currentBidPrice) {
            revert InvalidBidPrice();
        }

        // check if new bider is not the nftOwner
        // require(
        //     msg.sender != auction.creator,
        //     "Creator of the auction cannot place new bid"
        // );
        if (msg.sender == auction.creator) {
            revert OwnerCannotBid();
        }

        // new bid is better than current bid!

        // transfer token from new bider account to the marketplace account
        // to lock the tokens

        // new bid is valid so must refund the current bid owner (if there is one!)
        if (auction.bidCount > 0) {
            payable(auction.currentBidOwner).transfer(auction.currentBidPrice);
        }

        // update auction info
        address payable newBidOwner = payable(msg.sender);
        auction.currentBidOwner = newBidOwner;
        auction.currentBidPrice = msg.value;
        auction.bidCount++;

        // Trigger public event
        emit NewBidOnAuction(_auctionIndex, msg.value);

        return true;
    }

    /**
     * Function used by the creator of an auction
     * to get his NFT back in case the auction is closed
     * but there is no bider to make the NFT won't stay locked
     * in the contract
     * @param _auctionIndex Index of the auction
     */
    function cancelAuction(uint256 _auctionIndex) external {
        // require(_auctionIndex < allAuctions.length, "Invalid auction index");
        if (_auctionIndex > allAuctions.length) {
            revert InvalidAuction();
        }

        // Check if the auction is closed
        // require(!isOpen(_auctionIndex), "Auction is still open");
        if (isOpen(_auctionIndex)) {
            revert AuctionStillOpen();
        }

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the creator of the auction
        // require(
        //     auction.creator == msg.sender,
        //     "Tokens can be claimed only by the creator of the auction"
        // );
        if (auction.creator != msg.sender) {
            revert InvalidAuctionCreator();
        }

        // require(
        //     auction.currentBidOwner == address(0),
        //     "Existing bider for this auction"
        // );
        if (auction.currentBidOwner != address(0)) {
            revert AuctionHasBids();
        }

        // Get NFT Collection contract
        NFTDepotNFT nftCollection = NFTDepotNFT(auction.addressNFTCollection);
        // Transfer NFT back from marketplace contract
        // to the creator of the auction
        nftCollection.transferFrom(
            address(this),
            auction.creator,
            auction.nftId
        );

        emit NFTRefunded(_auctionIndex, auction.nftId, msg.sender);
    }

    /**
     * Return the address of the current highest bider
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBidOwner(uint256 _auctionIndex)
        public
        view
        returns (address)
    {
        // require(_auctionIndex < allAuctions.length, "Invalid auction index");
        if (_auctionIndex > allAuctions.length) {
            revert InvalidAuction();
        }
        return allAuctions[_auctionIndex].currentBidOwner;
    }

    /**
     * Return the current highest bid price
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBid(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        // require(_auctionIndex < allAuctions.length, "Invalid auction index");
        if (_auctionIndex > allAuctions.length) {
            revert InvalidAuction();
        }
        return allAuctions[_auctionIndex].currentBidPrice;
    }

    function getAuctions() public view returns (Auction[] memory) {
        return allAuctions;
    }

    // Decision pending for the claim token function

    /**
     * Function used by the creator of an auction
     * to withdraw his shares of the token
     * @param _auctionIndex Index of the auction
     */
    function claimToken(uint256 _auctionIndex) external payable nonReentrant {
        // require(_auctionIndex < allAuctions.length, "Invalid auction index"); // XXX Optimize
        if (_auctionIndex > allAuctions.length) {
            revert InvalidAuction();
        }

        // Check if the auction is closed
        // require(!isOpen(_auctionIndex), "Auction is still open");
        if (isOpen(_auctionIndex)) {
            revert AuctionStillOpen();
        }

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        //Check if bid has been placed

        // require(auction.bidCount > 0, "No bid to claim");
        if (auction.bidCount < 0) {
            revert NoBidsToClaim();
        }

        // Check if the caller is the creator of the auction
        // require(
        //     auction.creator == msg.sender,
        //     "Tokens can be claimed only by the creator of the auction"
        // );
        if (auction.creator != msg.sender) {
            revert InvalidAuctionCreator();
        }

        //Saving address of creator as temp
        address payable creator = auction.creator;

        //Setting creator to address 0 so thay may not abuse it
        auction.creator = payable(address(0));

        uint256 creatorCommision = calculateSellerMoney(
            auction.currentBidPrice
        );
        creator.transfer(creatorCommision);

        // Transfer locked tokens from the market place contract
        // to the wallet of the creator of the auction

        emit TokensClaimed(_auctionIndex, auction.nftId, msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}