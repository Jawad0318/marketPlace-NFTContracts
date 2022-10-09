// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";

//sdfsdfs

contract ERC721Template is Initializable, ERC721Upgradeable, EIP712Upgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, ERC721RoyaltyUpgradeable, OwnableUpgradeable {
    // constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string private constant SIGNING_DOMAIN = "NFTDepot-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    address public minter;
    mapping (uint256 => bool) private updatedTokens;

    event URIUpdated(uint256 tokenId, string uri);

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}
    struct LazyNFTVoucher {
        uint256 tokenId;
        uint256 price;
        string uri;
        address buyer;
        bytes signature;
    }

    function initialize(address _owner, string memory _name, string memory _symbol, address _minter) initializer public {
        __ERC721_init(_name, _symbol);
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        
        __ERC721Royalty_init();
        _setDefaultRoyalty(_owner, 500); // 5%

        _transferOwnership(_owner);
        minter = _minter;
    }

    function recover(LazyNFTVoucher calldata voucher) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("LazyNFTVoucher(uint256 tokenId,uint256 price,string uri,address buyer)"),
            voucher.tokenId,
            voucher.price,
            keccak256(bytes(voucher.uri)),
            voucher.buyer
        )));
        address signer = ECDSAUpgradeable.recover(digest, voucher.signature);
        return signer;
    }

    function safeMint(LazyNFTVoucher calldata voucher)
        public
        payable
    {
        require(minter == recover(voucher), "Wrong signature.");
        require(msg.value >= voucher.price, "Not enough ether sent.");
        _safeMint(voucher.buyer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function updateURI(uint256 tokenId, string memory uri) public {
        require(msg.sender == ownerOf(tokenId), "Only owner can update URI.");
        require(updatedTokens[tokenId] == false, "Token has already been updated.");

        updatedTokens[tokenId] = true;
        _setTokenURI(tokenId, uri);

        emit URIUpdated(tokenId, uri);
    }

    function supportsInterface(bytes4 interfaceId)
		public
		view
		override(
			ERC721Upgradeable,
			ERC721RoyaltyUpgradeable
		)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

}

