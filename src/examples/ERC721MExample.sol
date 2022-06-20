//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "solmate/auth/Owned.sol";

import "../ERC721MLockable.sol";

error ExceedsLimit();
error IncorrectValue();
error InvalidSignature();
error WhitelistNotActive();
error PublicSaleNotActive();
error SignatureExceedsLimit();
error ContractCallNotAllowed();

contract GMC is ERC721MLockable, Owned {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleStateUpdate();

    bool public publicSaleActive;

    string private baseURI;
    string private unrevealedURI = "ipfs://QmRuQYxmdzqfVfy8ZhZNTvXsmbN9yLnBFPDeczFvWUS2HU/";

    uint256 private constant MAX_SUPPLY = 5555;
    uint256 private constant MAX_PER_WALLET = 20;

    uint256 private constant price = 0.01 ether;
    uint256 private constant whitelistPrice = 0.01 ether;
    uint256 private constant PURCHASE_LIMIT = 10;

    bytes32 private constant BRIDGE_AUTHORITY = keccak256("BRIDGE_AUTHORITY");

    address private signerAddress = 0x68442589f40E8Fc3a9679dE62884c85C6E524888;

    mapping(address => uint256) public numMinted;

    constructor(address _checkpointManager, address _fxRoot)
        ERC721MLockable("GMC", "GMC", MAX_SUPPLY)
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {}

    /* ------------- External ------------- */

    function mint(uint256 quantity, bool lock) external payable onlyEOA {
        unchecked {
            if (!publicSaleActive) revert PublicSaleNotActive();
            if (PURCHASE_LIMIT < quantity) revert ExceedsLimit();
            if (msg.value != price * quantity) revert IncorrectValue();
            if ((numMinted[msg.sender] += quantity) > MAX_PER_WALLET) revert ExceedsLimit();

            if (lock) _mintLockedAndTransmit(msg.sender, quantity);
            else _mint(msg.sender, quantity);
        }
    }

    function mintAndTransmit(address to, uint256 quantity) external payable onlyEOA {
        unchecked {
            if (!publicSaleActive) revert PublicSaleNotActive();
            if (PURCHASE_LIMIT < quantity) revert ExceedsLimit();
            if (msg.value != price * quantity) revert IncorrectValue();
            if ((numMinted[msg.sender] += quantity) > MAX_PER_WALLET) revert ExceedsLimit();

            _mintLockedAndTransmit(msg.sender, quantity);
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
            if ((numMinted[msg.sender] += quantity) > limit) revert ExceedsLimit();

            if (lock) _mintLockedAndTransmit(msg.sender, quantity);
            else _mint(msg.sender, quantity);
        }
    }

    function lockAndTransmit(uint256[] calldata tokenIds) external payable {
        _lockAndTransmit(msg.sender, msg.sender, tokenIds);
    }

    function lockAndTransmit(address to, uint256[] calldata tokenIds) external payable {
        _lockAndTransmit(msg.sender, to, tokenIds);
    }

    // // @note necessary?
    // // could restrict with approval
    // function lockAndTransmitAuthority(
    //     address from,
    //     address to,
    //     uint256[] calldata tokenIds
    // ) external payable onlyRole(BRIDGE_AUTHORITY) {
    //     _lockAndTransmit(from, to, tokenIds);
    // }

    function unlockAndTransmit(uint256[] calldata tokenIds) external payable {
        _unlockAndTransmit(msg.sender, msg.sender, tokenIds);
    }

    function unlockAndTransmit(address to, uint256[] calldata tokenIds) external payable {
        _unlockAndTransmit(msg.sender, to, tokenIds);
    }

    function unlockAndTransmit(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external payable onlyRole(BRIDGE_AUTHORITY) {
        _unlockAndTransmit(from, to, tokenIds);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721MLockable, AccessControl) returns (bool) {
        return ERC721MLockable.supportsInterface(interfaceId);
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

    function giftMint(
        address[] calldata users,
        uint256[] calldata amounts,
        bool locked
    ) external onlyOwner {
        unchecked {
            if (locked) for (uint256 i; i < users.length; ++i) _mintLockedAndTransmit(users[i], amounts[i]);
            else for (uint256 i; i < users.length; ++i) _mint(users[i], amounts[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
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
