//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

// Contracts
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; // Includes Intialize, Context
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// Interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../interfaces/IOVRLandContainer.sol";

contract OVRMarketplace is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public token;
    address public feeReciver; //TODO feeReciver
    IERC721Upgradeable public OVRLand;
    uint256 public feePerc;
    IOVRLandContainer public OVRContainer;

    mapping(uint256 => Offer) public bestOffers;
    mapping(uint256 => OnSell) public selling;
    mapping(uint256 => OnSellContainer) public sellingContainer;
    mapping(uint256 => bool) public landOnSelling;
    mapping(uint256 => bool) public containerOnSelling;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _tokenAddress,
        address _OVRLandAddress,
        address _OVRContainer,
        uint256 _feeX100
    ) external initializer {
        token = IERC20Upgradeable(_tokenAddress);
        OVRLand = IERC721Upgradeable(_OVRLandAddress);
        OVRContainer = IOVRLandContainer(_OVRContainer);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        feePerc = _feeX100; // 5% -> 500
        feeReciver = _msgSender(); // TODO PASS INTO THE INITIALIZE
    }

    function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function removeAdminRole(address _admin)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /* ========== STRUCTS ========== */

    /**
     * @param from - _msgSender()
     * @param landId - NFT id
     * @param value - offer value in OVR token
     * @param timestamp - when offer was placed
     * @param fee - fee in OVR to pay to us for sell
     */
    struct Offer {
        address from;
        uint256 landId;
        uint256 value;
        uint256 fee;
        uint256 timestamp;
    }

    struct OnSell {
        address from;
        uint256 landId;
        uint256 value;
        uint256 fee;
        uint256 timestamp;
    }

    struct OnSellContainer {
        address from;
        uint256[] landId;
        uint256 value;
        uint256 fee;
        uint256 timestamp;
    }

    /* ========== EVENTS ========== */

    event OfferPlaced(
        address indexed sender,
        uint256 indexed nftId,
        uint256 value,
        uint256 timestamp
    );
    event OfferCancelled(
        uint256 indexed nftId,
        address indexed sender,
        address indexed to,
        uint256 timestamp
    );
    event OfferAccepted(
        address indexed owner,
        uint256 indexed nftId,
        address indexed to,
        uint256 value,
        uint256 timestamp
    );
    event Sold(
        address indexed seller,
        uint256 indexed nftId,
        uint256 value,
        uint256 timestamp
    );
    event ContainerSold(
        address indexed seller,
        uint256 indexed containerId,
        uint256 value,
        uint256 timestamp
    );
    event ContainerBought(
        uint256 indexed containerId,
        uint256 value,
        address indexed sender,
        uint256 timestamp
    );
    event SellCanceled(
        uint256 indexed nftId,
        address indexed sender,
        uint256 timestamp
    );
    event SellContainerCancelled(
        uint256 indexed containerId,
        address indexed sender,
        uint256 timestamp
    );
    event Bought(
        uint256 indexed nftId,
        uint256 value,
        address indexed sender,
        uint256 timestamp
    );
    event PriceContainerChanged(
        uint256 indexed containerId,
        uint256 newPrice,
        uint256 timestamp
    );
    event PriceLandChanged(
        uint256 indexed landId,
        uint256 newPrice,
        uint256 timestamp
    );

    /* ========== MODIFIERS ========== */

    modifier isLandOwner(uint256 _nftId) {
        require(
            OVRLand.ownerOf(_nftId) == _msgSender(),
            "Not the owner of this land"
        );
        _;
    }

    modifier isContainerOwner(uint256 _containerId) {
        require(
            OVRContainer.ownerOf(_containerId) == _msgSender(),
            "Not the owner of container"
        );
        _;
    }

    modifier isLandOwnerOrOfferer(uint256 _nftId) {
        require(
            _msgSender() == bestOffers[_nftId].from ||
                OVRLand.ownerOf(_nftId) == _msgSender(),
            "Not a offeror or land owner"
        );
        _;
    }

    modifier onSelling(uint256 _nftId) {
        require(
            selling[_nftId].from == OVRLand.ownerOf(_nftId),
            "Not for sale"
        ); //L'owner attuale non è chi l'ha messo in vendita
        _;
    }

    modifier onSellingContainer(uint256 _containerId) {
        require(
            sellingContainer[_containerId].from ==
                OVRContainer.ownerOf(_containerId),
            "Not for sale"
        ); //L'owner attuale non è chi l'ha messo in vendita
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function lastOffer(uint256 _nftId)
        public
        view
        returns (Offer memory _offer)
    {
        return bestOffers[_nftId];
    }

    function sellView(uint256 _nftId)
        public
        view
        onSelling(_nftId)
        returns (OnSell memory _sell)
    {
        return selling[_nftId];
    }

    function landIsOnSelling(uint256 _landId)
        public
        view
        returns (bool _onSelling)
    {
        return landOnSelling[_landId];
    }

    function containerIsOnSelling(uint256 _containerId)
        public
        view
        returns (bool _onSelling)
    {
        return containerOnSelling[_containerId];
    }

    function sellViewContainer(uint256 _containerId)
        public
        view
        onSellingContainer(_containerId)
        returns (OnSellContainer memory _sell)
    {
        return sellingContainer[_containerId];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setFeeAddr(address _feeAddr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeReciver = _feeAddr;
    }

    function setOVRLandContainerAddress(address _addr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        OVRContainer = IOVRLandContainer(_addr);
    }

    /**
     * @notice function to place an offer for a specified land by everyone
     * @dev if a bid is outbid, the bidder of the outbid bid will get back the tokens thanks to the moneyBack() function;
     * the bidder will send tokens to the contract (this to avoid fake offers)
     */
    function placeOffer(uint256 _nftId, uint256 _value) public whenNotPaused {
        require(_value > bestOffers[_nftId].value, "Offer is too low!");
        uint256 currentTimestamp = _now();

        moneyBack(_nftId);

        uint256 fees = _value.mul(feePerc).div(1e4);
        bestOffers[_nftId].fee = fees;
        bestOffers[_nftId].landId = _nftId;
        bestOffers[_nftId].from = _msgSender();
        bestOffers[_nftId].value = _value;
        bestOffers[_nftId].timestamp = currentTimestamp;

        uint256 totalToPay = fees.add(_value);

        require(
            token.transferFrom(_msgSender(), address(this), totalToPay),
            "Insufficient allowance"
        );
        emit OfferPlaced(_msgSender(), _nftId, _value, currentTimestamp);
    }

    /**
     * @notice this function can be called by the owner of the land to accept an offer of selling
     * @dev it will receive the tokens from the contract because the bidder sent money to this contract when made the offer
     **/
    function acceptOffer(uint256 _nftId)
        public
        isLandOwner(_nftId)
        whenNotPaused
    {
        address to = bestOffers[_nftId].from;
        require(bestOffers[_nftId].from != address(0), "No offers");
        require(
            token.transfer(_msgSender(), bestOffers[_nftId].value),
            "Insufficient contract balance"
        );
        require(
            token.transfer(feeReciver, bestOffers[_nftId].fee),
            "Insufficient contract balance"
        );

        uint256 currentTimestamp = _now();

        OVRLand.transferFrom(_msgSender(), bestOffers[_nftId].from, _nftId);
        landOnSelling[_nftId] = false;
        uint256 value = bestOffers[_nftId].value;
        delete bestOffers[_nftId];
        delete selling[_nftId];

        emit OfferAccepted(_msgSender(), _nftId, to, value, currentTimestamp);
    }

    /**
     * @notice this function can be called by the owner of the land to sell it
     **/
    function sell(uint256 _nftId, uint256 _value)
        public
        isLandOwner(_nftId)
        whenNotPaused
    {
        /**
         * Give the owner the ability to overwrite the sale if
         * the old owner did not cancel the previous sale.
         **/
        require(
            landOnSelling[_nftId] == false ||
                selling[_nftId].from != OVRLand.ownerOf(_nftId),
            "Already on selling"
        );
        uint256 fees = _value.mul(feePerc).div(1e4);
        uint256 currentTimestamp = _now();
        selling[_nftId].fee = fees;
        selling[_nftId].landId = _nftId;
        selling[_nftId].from = _msgSender();
        selling[_nftId].value = _value;
        selling[_nftId].timestamp = currentTimestamp;
        landOnSelling[_nftId] = true;
        emit Sold(_msgSender(), _nftId, _value, currentTimestamp);
    }

    /**
     * @notice this function can be called by the owner of a container to sell a it
     *
     **/
    function sellContainer(uint256 _containerId, uint256 _value)
        public
        isContainerOwner(_containerId)
        whenNotPaused
    {
        uint256 fees = _value.mul(feePerc).div(1e4);
        sellingContainer[_containerId].fee = fees;
        sellingContainer[_containerId].landId = OVRContainer.childsOfParent(
            _containerId
        );
        sellingContainer[_containerId].from = _msgSender();
        sellingContainer[_containerId].value = _value;
        sellingContainer[_containerId].timestamp = _now();
        containerOnSelling[_containerId] = true;
        emit ContainerSold(_msgSender(), _containerId, _value, _now());
    }

    /**
     * @notice this function can be called by everyone to buy a container which was previously put up for sale by the owner
     * @dev if the current owner of all the lands is not the same person who put the lands up for sale, the container cannot be bought
     **/
    function buyContainer(uint256 _containerId)
        public
        whenNotPaused
        onSellingContainer(_containerId)
    {
        uint256 minBalance = sellingContainer[_containerId].value.add(
            sellingContainer[_containerId].fee
        );
        require(
            token.balanceOf(_msgSender()) >= minBalance,
            "Not enough balance"
        );
        require(
            token.transferFrom(
                _msgSender(),
                sellingContainer[_containerId].from,
                sellingContainer[_containerId].value
            ),
            "Insufficient allowance"
        );
        require(
            token.transferFrom(
                _msgSender(),
                feeReciver,
                sellingContainer[_containerId].fee
            ),
            "Insufficient allowance"
        );
        OVRContainer.transferFrom(
            sellingContainer[_containerId].from,
            _msgSender(),
            _containerId
        );

        containerOnSelling[_containerId] = false;
        uint256 currentTimestamp = _now();
        uint256 value = sellingContainer[_containerId].value;

        delete sellingContainer[_containerId];

        emit ContainerBought(
            _containerId,
            value,
            _msgSender(),
            currentTimestamp
        );
    }

    /**
     * @notice function to cancel an offer by the owner of the land or the offeror
     * @dev it will give back the money to the offeror
     */
    function cancelOffer(uint256 _nftId) public isLandOwnerOrOfferer(_nftId) {
        uint256 currentTimestamp = _now();
        moneyBack(_nftId);
        address to = bestOffers[_nftId].from;
        delete bestOffers[_nftId];
        emit OfferCancelled(_nftId, _msgSender(), to, currentTimestamp);
    }

    /**
     * @notice delete container on selling, can be called only by the person that own the container
     **/
    function cancelSellContainer(uint256 _containerId)
        public
        isContainerOwner(_containerId)
    {
        uint256 currentTimestamp = _now();
        containerOnSelling[_containerId] = false;
        delete sellingContainer[_containerId];
        emit SellContainerCancelled(
            _containerId,
            _msgSender(),
            currentTimestamp
        );
    }

    /**
     * @notice change price container on selling, can be called only by the person that own the container
     **/
    function updatePriceContainer(uint256 _containerId, uint256 _price)
        public
        isContainerOwner(_containerId)
    {
        require(
            containerOnSelling[_containerId] == true,
            "Container not on selling"
        );
        uint256 fees = _price.mul(feePerc).div(1e4);
        uint256 currentTimestamp = _now();
        sellingContainer[_containerId].value = _price;
        sellingContainer[_containerId].fee = fees;
        emit PriceContainerChanged(_containerId, _price, currentTimestamp);
    }

    /**
     * @notice change price land on selling, can be called only by the person that own the land
     **/
    function updatePriceLand(uint256 _nftId, uint256 _price)
        public
        isLandOwner(_nftId)
    {
        require(landOnSelling[_nftId] == true, "Container not on selling");
        uint256 fees = _price.mul(feePerc).div(1e4);
        uint256 currentTimestamp = _now();
        selling[_nftId].value = _price;
        selling[_nftId].fee = fees;
        emit PriceLandChanged(_nftId, _price, currentTimestamp);
    }

    /**
     * @notice delete land on selling, can be called only by the person that own the land
     **/
    function cancelSell(uint256 _nftId) public isLandOwner(_nftId) {
        uint256 currentTimestamp = _now();
        landOnSelling[_nftId] = false;
        delete selling[_nftId];
        emit SellCanceled(_nftId, _msgSender(), currentTimestamp);
    }

    /**
     * @notice this function can be called by everyone to buy a land which was previously put up for sale by the owner
     * @dev if the current owner of the land is not the same person who put the land up for sale, the land cannot be bought
     **/
    function buy(uint256 _nftId) public whenNotPaused onSelling(_nftId) {
        uint256 minBalance = selling[_nftId].value.add(selling[_nftId].fee);
        require(
            token.balanceOf(_msgSender()) >= minBalance,
            "Not enough balance"
        );
        require(
            token.transferFrom(
                _msgSender(),
                selling[_nftId].from,
                selling[_nftId].value
            ),
            "Insufficient allowance"
        );
        require(
            token.transferFrom(_msgSender(), feeReciver, selling[_nftId].fee),
            "Insufficient allowance"
        );
        OVRLand.transferFrom(selling[_nftId].from, _msgSender(), _nftId);
        uint256 currentTimestamp = _now();
        uint256 value = selling[_nftId].value;
        delete selling[_nftId];
        landOnSelling[_nftId] = false;
        emit Bought(_nftId, value, _msgSender(), currentTimestamp);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice this function will give back money to bidders when they cancel their offer, or their offer is outbid
     **/
    function moneyBack(uint256 _nftId) internal nonReentrant {
        if (bestOffers[_nftId].from != address(0)) {
            uint256 oldFee = bestOffers[_nftId].fee;
            address from = bestOffers[_nftId].from;
            uint256 paid = bestOffers[_nftId].value;

            uint256 totalToReturn = paid.add(oldFee);
            bestOffers[_nftId].from = address(0);
            require(
                token.transfer(from, totalToReturn),
                "Insufficient contract balance"
            );
        }
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    /**
     * @return Returns current timestamp.
     */
    function _now() internal view returns (uint256) {
        // Note that the timestamp can have a 900-second error:
        // https://github.com/ethereum/wiki/blob/c02254611f218f43cbb07517ca8e5d00fd6d6d75/Block-Protocol-2.0.md
        // return now; // solium-disable-line security/no-block-members
        return block.timestamp;
    }
}
