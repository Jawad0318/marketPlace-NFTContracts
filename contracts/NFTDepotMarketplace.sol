// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTDepotAuctions.sol";

error PriceNotMet(address _addressNFTCollection, uint256 nftId, uint256 price);
error ItemNotForSale(address _addressNFTCollection, uint256 nftId);
error NotListed(address _addressNFTCollection, uint256 nftId);
error AlreadyListed(address _addressNFTCollection, uint256 nftId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();

contract NFTDepotMarketplace is NFTDepotAuctions {
    // Name of the marketplace
    string public name;

    uint256 public offerId;

    uint256 public listingIndex;

    struct Listing {
        uint256 L_index;
        uint256 price;
        address payable seller;
        bool isListedState;
    }

    struct ListingsRecord {
        uint256 L_index;
        address _addressNFTCollection;
        uint256 NFTId;
        bool isListed;
    }

    struct Offers {
        uint256 offerId;
        address sender;
        address reciever;
        address _addressNFTCollection;
        uint256 id;
        uint256 price;
        bool accepted;
        bool cancel;
    }

    // event ItemListed(
    //     address indexed seller,
    //     address indexed _addressNFTCollection,
    //     uint256 indexed nftId,
    //     uint256 price
    // );

    // event ItemCanceled(
    //     address indexed seller,
    //     address indexed _addressNFTCollection,
    //     uint256 indexed nftId
    // );

    // event ItemBought(
    //     address indexed buyer,
    //     address indexed _addressNFTCollection,
    //     uint256 indexed nftId,
    //     uint256 price
    // );

    // event OfferCreated(
    //     uint256 id,
    //     address sender,
    //     address reciever,
    //     address _addressNFTCollection,
    //     uint256 NFTId,
    //     uint256 price
    // );

    // event OfferCancelled(
    //     uint256 id,
    //     address sender,
    //     address reciever,
    //     address _addressNFTCollection,
    //     uint256 NFTId,
    //     uint256 price,
    //     bool canceled
    // );

    // event OfferAccepted(
    //     uint256 id,
    //     address sender,
    //     address reciever,
    //     address _addressNFTCollection,
    //     uint256 NFTId,
    //     uint256 price
    // );

    ListingsRecord[] public allListings;

    Offers[] public allOffers;

    mapping(address => mapping(uint256 => Listing)) public s_listings;

    modifier notListed(
        address _addressNFTCollection,
        uint256 nftId,
        address nftOwner
    ) {
        Listing memory listing = s_listings[_addressNFTCollection][nftId];
        if (listing.price > 0) {
            revert AlreadyListed(_addressNFTCollection, nftId);
        }
        _;
    }

    modifier isListed(address _addressNFTCollection, uint256 nftId) {
        Listing memory listing = s_listings[_addressNFTCollection][nftId];
        if (listing.price <= 0) {
            revert NotListed(_addressNFTCollection, nftId);
        }
        _;
    }

    modifier isOwner(
        address _addressNFTCollection,
        uint256 nftId,
        address spender
    ) {
        NFTDepotNFT nft = NFTDepotNFT(_addressNFTCollection);
        address nftOwner = nft.ownerOf(nftId);
        if (spender != nftOwner) {
            revert NotOwner();
        }
        _;
    }

    // constructor of the contract
    constructor(string memory _name) {
        name = _name;
    }

    /////////////////////
    // Main Functions //
    /////////////////////

    /**
     * @notice Method for listing NFT
     * @param _addressNFTCollection Address of NFT contract
     * @param nftId Token ID of NFT
     * @param price sale price for each item
     */
    function listItem(
        address _addressNFTCollection,
        uint256 nftId,
        uint256 price
    )
        external
        payable
        notListed(_addressNFTCollection, nftId, msg.sender)
        isOwner(_addressNFTCollection, nftId, msg.sender)
    {
        require(msg.value >= listingFee, "insufficient Fees");
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        NFTDepotNFT nft = NFTDepotNFT(_addressNFTCollection);
        if (nft.getApproved(nftId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        s_listings[_addressNFTCollection][nftId] = Listing(
            listingIndex,
            price,
            payable(msg.sender),
            true
        );

        allListings.push(
            ListingsRecord(listingIndex, _addressNFTCollection, nftId, true)
        );
        listingIndex++;

        // emit ItemListed(msg.sender, _addressNFTCollection, nftId, price);
    }

    function sendOffer(
        address _addressNFTCollection,
        uint256 nftId
    ) public payable isListed(_addressNFTCollection, nftId) {
        // require(!isContract(msg.sender), "Sender must be user");
        NFTDepotNFT nft = NFTDepotNFT(_addressNFTCollection);
        address ownerOfNFT = nft.ownerOf(nftId);
        allOffers.push(
            Offers(
                offerId,
                payable(msg.sender),
                payable(ownerOfNFT),
                _addressNFTCollection,
                nftId,
                msg.value,
                false,
                false
            )
        );
        offerId++;
        // emit OfferCreated(
        //     offerId,
        //     msg.sender,
        //     ownerOfNFT,
        //     _addressNFTCollection,
        //     nftId,
        //     price
        // );
    }

    function cancelOffer(uint256 _offerId) public payable nonReentrant {
        Offers storage offer = allOffers[_offerId];
        require(offer.sender == msg.sender);
        require(!offer.cancel);
        require(!offer.accepted);
        offer.cancel = true;
        payable(offer.sender).transfer(offer.price);
        // emit OfferCancelled(
        //     offer.offerId,
        //     offer.sender,
        //     offer.reciever,
        //     offer._addressNFTCollection,
        //     offer.id,
        //     offer.price,
        //     offer.cancel
        // );
    }

    function acceptOffer(uint256 _offerId) public payable nonReentrant {
        Offers storage offer = allOffers[_offerId];
        Listing memory listedItem = s_listings[offer._addressNFTCollection][
            offer.id
        ];
        if (listedItem.price <= 0) {
            revert NotListed(offer._addressNFTCollection, offer.id);
        }
        require(offer.reciever == msg.sender);
        require(!offer.cancel);
        require(!offer.accepted);
        offer.accepted = true;
        listedItem.isListedState = false;
        uint256 listingLocation = s_listings[offer._addressNFTCollection][
            offer.id
        ].L_index;
        ListingsRecord storage listingss = allListings[listingLocation];
        listingss.isListed = false;
        delete (s_listings[offer._addressNFTCollection][offer.id]);

        NFTDepotNFT(offer._addressNFTCollection).safeTransferFrom(
            listedItem.seller,
            payable(msg.sender),
            offer.id
        );

        // calculating and transfering royalties
        uint256 royaltyAmountToTransfer = calculateRoyalties(
            offer._addressNFTCollection,
            offer.price
        );
        address collectionOwner = getRoyaltyReciever(
            offer._addressNFTCollection
        );
        payable(collectionOwner).transfer(royaltyAmountToTransfer);

        // Calculating seller commisions

        uint256 sellerMoneyFromSale = calculateSellerMoney(offer.price);

        //transfering shares

        payable(msg.sender).transfer(sellerMoneyFromSale);

        // emit OfferAccepted(offer.id, offer.sender, offer.reciever, offer._addressNFTCollection, offer.id, offer.price);
    }

        function getAllOffers() public view returns (Offers[] memory) {
        return allOffers;
    }

    /**
     * @notice Method for cancelling listing
     * @param _addressNFTCollection Address of NFT contract
     * @param nftId Token ID of NFT
     */
    function cancelListing(address _addressNFTCollection, uint256 nftId)
        external
        isOwner(_addressNFTCollection, nftId, msg.sender)
        isListed(_addressNFTCollection, nftId)
    {
        uint256 listingLocation = s_listings[_addressNFTCollection][nftId]
            .L_index;
        ListingsRecord storage listingss = allListings[listingLocation];
        listingss.isListed = false;
        delete (s_listings[_addressNFTCollection][nftId]);
        // emit ItemCanceled(msg.sender, _addressNFTCollection, nftId);
    }

    /**
     * @notice Method for buying listing
     * @notice The nftOwner of an NFT could unapprove the marketplace,
     * which would cause this function to fail
     * Ideally you'd also have a `createOffer` functionality.
     * @param _addressNFTCollection Address of NFT contract
     * @param nftId Token ID of NFT
     */
    function buyItem(address _addressNFTCollection, uint256 nftId)
        external
        payable
        isListed(_addressNFTCollection, nftId)
        nonReentrant
    {
        Listing memory listedItem = s_listings[_addressNFTCollection][nftId];
        // if (msg.value < listedItem.price * (10**18)) might need to do this if not handled in the frontend
        if (msg.value < listedItem.price) {
            revert PriceNotMet(_addressNFTCollection, nftId, listedItem.price);
        }

        listedItem.isListedState = false;
        uint256 listingLocation = s_listings[_addressNFTCollection][nftId]
            .L_index;
        ListingsRecord storage listingss = allListings[listingLocation];
        listingss.isListed = false;
        delete (s_listings[_addressNFTCollection][nftId]);

        NFTDepotNFT(_addressNFTCollection).safeTransferFrom(
            listedItem.seller,
            payable(msg.sender),
            nftId
        );

        // calculating and transfering royalties
        uint256 royaltyAmountToTransfer = calculateRoyalties(
            _addressNFTCollection,
            msg.value
        );
        address collectionOwner = getRoyaltyReciever(_addressNFTCollection);
        payable(collectionOwner).transfer(royaltyAmountToTransfer);

        // Calculating seller commisions

        uint256 sellerMoneyFromSale = calculateSellerMoney(msg.value);

        //transfering shares

        payable(msg.sender).transfer(sellerMoneyFromSale);

        // emit ItemBought(
        //     msg.sender,
        //     _addressNFTCollection,
        //     nftId,
        //     listedItem.price
        // );
    }

    /**
     * @notice Method for updating listing
     * @param _addressNFTCollection Address of NFT contract
     * @param nftId Token ID of NFT
     * @param newPrice Price in Wei of the item
     */
    function updateListing(
        address _addressNFTCollection,
        uint256 nftId,
        uint256 newPrice
    )
        external
        isListed(_addressNFTCollection, nftId)
        nonReentrant
        isOwner(_addressNFTCollection, nftId, msg.sender)
    {
        //We should check the value of `newPrice` and revert if it's below zero (like we also check in `listItem()`)
        if (newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        s_listings[_addressNFTCollection][nftId].price = newPrice;
        // emit ItemListed(msg.sender, _addressNFTCollection, nftId, newPrice);
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function getmarketPercentageCommision() public view returns (uint256) {
        return marketPercentageCommision;
    }

    function getListing(address _addressNFTCollection, uint256 nftId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[_addressNFTCollection][nftId];
    }

    function getTotalFunds() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /**
     * Create a new auction of a specific NFT
     * @param _to address of a wallett to transfer all the funds in the contract
     */
    function withdrawfunds(address payable _to) external payable onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**
     * Create a new auction of a specific NFT
     * @param _addressNFTCollection address of the ERC721 NFT collection contract
     * @param _nftId Id of the NFT for sale
     * @param _initialBid Inital bid decided by the creator of the auction
     * @param endAuction Timestamp with the end date and time of the auction
     */

    function createAuction(
        address _addressNFTCollection,
        uint256 _nftId,
        uint256 _initialBid,
        uint256 endAuction
    ) external returns (uint256) {
        //Check is addresses are valid
        uint256 _endAuction = convertMinToSec(endAuction);
        require(endAuction <= auctionTimeLimit, "Less than 2 days");
        // require(
        //     isContract(_addressNFTCollection),
        //     "Invalid contract address"
        // );

        // Check if the endAuction time is valid
        // require(_endAuction > block.timestamp, "Invalid end date for auction");

        // Check if the initial bid price is > 0
        require(_initialBid > 0, "Invalid price");

        // Get NFT collection contract
        NFTDepotNFT nftCollection = NFTDepotNFT(_addressNFTCollection);

        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the nftOwner of this NFT
        require(
            nftCollection.ownerOf(_nftId) == msg.sender,
            "Caller not nftOwner"
        );

        require(
            s_listings[_addressNFTCollection][_nftId].isListedState == false,
            "NFT not listed"
        );
        // Make sure the nftOwner of the NFT approved that the MarketPlace contract
        // is allowed to change nftOwnership of the NFT
        require(
            nftCollection.getApproved(_nftId) == address(this)
        );

        // Lock NFT in Marketplace contract
        nftCollection.transferFrom(msg.sender, address(this), _nftId);

        //Casting from address to address payable
        address payable currentBidOwner = payable(address(0));
        // Create new Auction object
        Auction memory newAuction = Auction({
            index: index,
            addressNFTCollection: _addressNFTCollection,
            nftId: _nftId,
            creator: payable(msg.sender),
            currentBidOwner: currentBidOwner,
            currentBidPrice: _initialBid,
            endAuction: (block.timestamp + _endAuction),
            bidCount: 0
        });

        //update list
        allAuctions.push(newAuction);

        // increment auction sequence
        index++;

        // Trigger event and return index of new auction
        emit NewAuction(
            index,
            _addressNFTCollection,
            _nftId,
            msg.sender,
            currentBidOwner,
            _initialBid,
            _endAuction,
            0
        );
        return index;
    }

    function getAllListings() public view returns (ListingsRecord[] memory) {
        return allListings;
    }

    /**
     * Function used by the winner of an auction
     * to withdraw his NFT.
     * When the NFT is withdrawn, the creator of the
     * auction will receive the payment tokens in his wallet
     * @param _auctionIndex Index of auction
     */
    function claimNFT(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length);

        // Check if the auction is closed
        require(!isOpen(_auctionIndex));

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the winner of the auction
        require(auction.currentBidOwner == msg.sender);

        // Get NFT collection contract
        NFTDepotNFT nftCollection = NFTDepotNFT(auction.addressNFTCollection);
        // Transfer NFT from marketplace contract
        // to the winner address

        nftCollection.transferFrom(
            address(this),
            auction.currentBidOwner,
            _auctionIndex
        );

        delete (s_listings[auction.addressNFTCollection][auction.nftId]);

        // emit NFTClaimed(_auctionIndex, auction.nftId, msg.sender);
    }
}
