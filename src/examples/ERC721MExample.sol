//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/auth/Owned.sol";
import "solmate/utils/LibString.sol";

import "../extensions/ERC721MStaking.sol";

error ExceedsLimit();
error IncorrectValue();
error NonexistentToken();
error InvalidSignature();
error WhitelistNotActive();
error PublicSaleNotActive();
error SignatureExceedsLimit();
error ContractCallNotAllowed();

contract GMC is ERC721MStaking, Owned {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleStateUpdate();

    bool public publicSaleActive;

    string public constant override name = "My NFT";
    string public constant override symbol = "NFT";

    string private baseURI;
    string private unrevealedURI = "ipfs://QSOZMCWOM/";

    uint256 private constant MAX_SUPPLY = 5555;
    uint256 private constant MAX_PER_WALLET = 20;

    uint256 private constant price = 0.02 ether;
    uint256 private constant whitelistPrice = 0.01 ether;
    uint256 private constant PURCHASE_LIMIT = 10;

    address private signerAddress = address(0xb0b);

    constructor(IERC20 token) ERC721MStaking(token) Owned(msg.sender) {}

    /* ------------- external ------------- */

    function mint(uint256 quantity, bool lock) external payable onlyEOA {
        unchecked {
            if (!publicSaleActive) revert PublicSaleNotActive();
            if (PURCHASE_LIMIT < quantity) revert ExceedsLimit();
            if (msg.value != price * quantity) revert IncorrectValue();
            if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsLimit();
            if (numMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsLimit();

            if (lock) _mintAndStake(msg.sender, quantity);
            else _mint(msg.sender, quantity);
        }
    }

    function whitelistMint(
        uint256 quantity,
        bool lock,
        uint256 limit,
        bytes calldata signature
    ) external payable onlyEOA {
        unchecked {
            if (!validSignature(signature, limit)) revert InvalidSignature();
            if (msg.value != whitelistPrice * quantity) revert IncorrectValue();
            if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsLimit();
            if (numMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsLimit();

            if (lock) _mintAndStake(msg.sender, quantity);
            else _mint(msg.sender, quantity);
        }
    }

    function stake(uint256[] calldata tokenIds) public {
        _stake(msg.sender, tokenIds);
    }

    function unstake(uint256[] calldata tokenIds) public {
        _unstake(msg.sender, tokenIds);
    }

    /* ------------- Private ------------- */

    function validSignature(bytes calldata signature, uint256 limit) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), msg.sender, limit));
        return msgHash.toEthSignedMessageHash().recover(signature) == signerAddress;
    }

    /* ------------- Owner ------------- */

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit SaleStateUpdate();
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string calldata _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setSignerAddress(address _address) external onlyOwner {
        signerAddress = _address;
    }

    function airdrop(
        address[] calldata users,
        uint256[] calldata amounts,
        bool locked
    ) external onlyOwner {
        unchecked {
            if (locked) for (uint256 i; i < users.length; ++i) _mintAndStake(users[i], amounts[i]);
            else for (uint256 i; i < users.length; ++i) _mint(users[i], amounts[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance); // don't use this for multisigs like gnosis
    }

    /* ------------- Modifier ------------- */

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }

    /* ------------- ERC721 ------------- */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();

        if (bytes(baseURI).length == 0) return unrevealedURI;

        return string.concat(baseURI, tokenId.toString(), ".json");
    }
}
