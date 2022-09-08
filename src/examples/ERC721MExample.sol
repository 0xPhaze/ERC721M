//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/auth/Owned.sol";
import "./lib/LibString.sol";
import "./lib/LibECDSA.sol";

import "../extensions/ERC721MStaking.sol";

error ExceedsLimit();
error IncorrectValue();
error NonexistentToken();
error InvalidSignature();
error WhitelistNotActive();
error PublicSaleNotActive();
error SignatureExceedsLimit();
error ContractCallNotAllowed();

contract StakingNFT is ERC721MStaking, Owned {
    using LibString for uint256;
    using LibECDSA for bytes32;

    event SaleStateUpdate();

    bool public publicSaleActive;

    string private baseURI;
    string private unrevealedURI = "ipfs://QSOZMCWOM/";

    uint256 private constant MAX_SUPPLY = 5555;
    uint256 private constant MAX_PER_WALLET = 20;

    uint256 private constant price = 0.02 ether;
    uint256 private constant whitelistPrice = 0.01 ether;
    uint256 private constant PURCHASE_LIMIT = 5;

    address private signerAddress = address(0xb0b);

    uint256 private immutable _rewardEndDate = block.timestamp + 5 * 365 days;

    constructor(
        string memory name,
        string memory symbol,
        address token
    ) ERC721M(name, symbol) ERC721MStaking(token) Owned(msg.sender) {}

    /* ------------- override ------------- */

    function rewardEndDate() public view override returns (uint256) {
        return _rewardEndDate;
    }

    function rewardDailyRate() public pure override returns (uint256) {
        return 1e18;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) revert NonexistentToken();

        return (bytes(baseURI).length == 0) ? unrevealedURI : string.concat(baseURI, id.toString(), ".json");
    }

    /* ------------- external ------------- */

    function mint(uint256 quantity, bool lock) external payable onlyEOA {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (PURCHASE_LIMIT < quantity) revert ExceedsLimit();
        if (msg.value != price * quantity) revert IncorrectValue();
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsLimit();
        if (numMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsLimit();

        if (lock) _mintAndStake(msg.sender, quantity);
        else _mint(msg.sender, quantity);
    }

    function whitelistMint(
        uint256 quantity,
        bool lock,
        uint256 limit,
        bytes calldata signature
    ) external payable onlyEOA {
        if (!validSignature(signature, limit)) revert InvalidSignature();
        if (msg.value != whitelistPrice * quantity) revert IncorrectValue();
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsLimit();
        if (numMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsLimit();

        if (lock) _mintAndStake(msg.sender, quantity);
        else _mint(msg.sender, quantity);
    }

    /* ------------- private ------------- */

    function validSignature(bytes calldata signature, uint256 limit) private view returns (bool) {
        bytes32 hash = keccak256(abi.encode(address(this), msg.sender, limit));
        return hash.toEthSignedMsgHash().isValidSignature(signature, signerAddress);
    }

    /* ------------- owner ------------- */

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
        if (locked) for (uint256 i; i < users.length; ++i) _mintAndStake(users[i], amounts[i]);
        else for (uint256 i; i < users.length; ++i) _mint(users[i], amounts[i]);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance); // don't use this for multisigs like gnosis
    }

    /* ------------- modifier ------------- */

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }
}
