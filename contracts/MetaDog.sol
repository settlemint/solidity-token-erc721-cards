// SPDX-License-Identifier: MIT
// SettleMint.com

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721Whitelist} from "./extensions/ERC721Whitelist.sol";
import {ERC721Freezable} from "./extensions/ERC721Freezable.sol";
import {ERC721MintPausable} from "./extensions/ERC721MintPausable.sol";
import {ERC721OpenSeaGassLess} from "./extensions/ERC721OpenSeaGassLess.sol";
import {ERC721Batch} from "./extensions/ERC721Batch.sol";

contract MetaDog is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ERC721Whitelist,
    ERC721Freezable,
    ERC721MintPausable,
    ERC721OpenSeaGassLess,
    ERC721Batch,
    ERC721Royalty,
    Ownable,
    ReentrancyGuard
{
    //////////////////////////////////////////////////////////////////
    // CONFIGURATION                                                //
    //////////////////////////////////////////////////////////////////

    uint256 public constant RESERVES = 5; // amount of tokens for the team, or to sell afterwards
    uint256 public constant PRICE_IN_WEI_WHITELIST = 0.0069 ether; // price per token in the whitelist sale
    uint256 public constant PRICE_IN_WEI_PUBLIC = 0.042 ether; // price per token in the public sale
    uint96 public constant ROYALTIES_IN_BASIS_POINTS = 500; // 5% royalties
    uint256 public constant MAX_PER_TX = 5; // maximum amount of tokens one can mint in one transaction
    uint256 public constant MAX_SUPPLY = 111; // the total amount of tokens for this NFT

    //////////////////////////////////////////////////////////////////
    // TOKEN STORAGE                                                //
    //////////////////////////////////////////////////////////////////

    uint256 private _tokenId;
    string private _baseTokenURI; // the IPFS url to the folder holding the metadata.

    //////////////////////////////////////////////////////////////////
    // CROWDSALE STORAGE                                            //
    //////////////////////////////////////////////////////////////////

    address payable private immutable _wallet; // adress of the wallet which received the funds
    mapping(address => uint256) private _addressToMinted; // the amount of tokens an address has minted
    bool private _publicSaleOpen = false; // is the public sale open?

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address proxyRegistryAddress_,
        address payable wallet_
    )
        ERC721(name_, symbol_)
        ERC721OpenSeaGassLess(proxyRegistryAddress_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
        _wallet = wallet_;
        _setDefaultRoyalty(wallet_, ROYALTIES_IN_BASIS_POINTS);
    }

    //////////////////////////////////////////////////////////////////
    // CORE FUNCTIONS                                               //
    //////////////////////////////////////////////////////////////////

    function setBaseURI(
        string memory baseTokenURI_
    ) public onlyOwner whenURINotFrozen {
        _baseTokenURI = baseTokenURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory tokenUri = super.tokenURI(tokenId);
        return
            bytes(tokenUri).length > 0
                ? string(abi.encodePacked(tokenUri, ".json"))
                : "";
    }

    function update(
        address to,
        uint256 tokenId,
        address auth
    ) public returns (address) {
        return _update(to, tokenId, auth);
    }

    function increaseBalance(address account, uint128 value) public {
        _increaseBalance(account, value);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        virtual
        override(
            ERC721Enumerable,
            ERC721,
            ERC721Freezable,
            ERC721Pausable,
            ERC721MintPausable
        )
        returns (address)
    {
        // your code here
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    //////////////////////////////////////////////////////////////////
    // RESERVE TOKENS                                               //
    //////////////////////////////////////////////////////////////////

    function collectReserves() public onlyOwner {
        require(_tokenId == 0, "Reserves already collected");
        for (uint256 i = 1; i <= RESERVES; i++) {
            _mint(_wallet, ++_tokenId);
        }
    }

    function gift(address[] calldata recipients_) external onlyOwner {
        require(_tokenId > 0, "Reserves not taken yet");
        uint256 recipients = recipients_.length;
        require(_tokenId + recipients <= MAX_SUPPLY, "Excedes max supply");
        for (uint256 i = 0; i < recipients; i++) {
            _mint(recipients_[i], ++_tokenId);
        }
    }

    //////////////////////////////////////////////////////////////////
    // WHITELIST SALE                                               //
    //////////////////////////////////////////////////////////////////

    function setWhitelistMerkleRoot(
        bytes32 whitelistMerkleRoot_
    ) external onlyOwner {
        _setWhitelistMerkleRoot(whitelistMerkleRoot_);
    }

    function whitelistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable nonReentrant {
        require(_tokenId > 0, "Reserves not taken yet");
        require(_tokenId + count <= MAX_SUPPLY, "Exceeds max supply");
        require(
            _validateWhitelistMerkleProof(allowance, proof),
            "Invalid Merkle Tree proof supplied"
        );
        require(
            _addressToMinted[_msgSender()] + count <= allowance,
            "Exceeds whitelist allowance"
        );
        require(
            count * PRICE_IN_WEI_WHITELIST == msg.value,
            "Invalid funds provided"
        );
        _addressToMinted[_msgSender()] += count;
        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), ++_tokenId);
        }
    }

    //////////////////////////////////////////////////////////////////
    // PUBLIC SALE                                                  //
    //////////////////////////////////////////////////////////////////

    function startPublicSale() external onlyOwner {
        _disableWhitelistMerkleRoot();
        _publicSaleOpen = true;
    }

    function publicMint(uint256 count) public payable nonReentrant {
        require(_whitelistMerkleRoot == 0, "Public sale not active");
        require(_publicSaleOpen, "Public sale not active");
        require(_tokenId > 0, "Reserves not taken yet");
        require(_tokenId + count <= MAX_SUPPLY, "Exceeds max supply");
        require(count < MAX_PER_TX, "Exceeds max per transaction");
        require(
            count * PRICE_IN_WEI_PUBLIC == msg.value,
            "Invalid funds provided"
        );

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), ++_tokenId);
        }
    }

    //////////////////////////////////////////////////////////////////
    // POST SALE MANAGEMENT                                         //
    //////////////////////////////////////////////////////////////////

    function withdraw() public onlyOwner {
        _wallet.transfer(address(this).balance);
    }

    function wallet() public view returns (address) {
        return _wallet;
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) {
        super.burn(tokenId);
    }

    function freeze() external onlyOwner {
        super._freeze();
    }

    //////////////////////////////////////////////////////////////////
    // GASLESS LISTING FOR OPENSEA                                  //
    //////////////////////////////////////////////////////////////////

    function setProxyRegistryAddress(
        address proxyRegistryAddress_
    ) external onlyOwner {
        _setProxyRegistryAddress(proxyRegistryAddress_);
    }

    function isApprovedForAll(
        address _owner,
        address operator
    )
        public
        view
        override(IERC721, ERC721, ERC721OpenSeaGassLess)
        returns (bool)
    {
        return super.isApprovedForAll(_owner, operator);
    }

    //////////////////////////////////////////////////////////////////
    // Pausable & MintPausable                                      //
    //////////////////////////////////////////////////////////////////

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pauseMint() public onlyOwner {
        _pauseMint();
    }

    function unpauseMint() public onlyOwner {
        _unpauseMint();
    }

    //////////////////////////////////////////////////////////////////
    // ERC165                                                       //
    //////////////////////////////////////////////////////////////////

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return
            interfaceId == type(Ownable).interfaceId ||
            interfaceId == type(ERC721Burnable).interfaceId ||
            interfaceId == type(ERC721Enumerable).interfaceId ||
            interfaceId == type(ERC721Whitelist).interfaceId ||
            interfaceId == type(ERC721Freezable).interfaceId ||
            interfaceId == type(ERC721MintPausable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
