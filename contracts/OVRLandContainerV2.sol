// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

// Interfaces
import "../interfaces/IMarketplace.sol";
import "../interfaces/IRenting.sol";

contract OVRLandContainerV2 is
    UUPSUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant FOLDER_URI_EDITOR_ROLE =
        keccak256("FOLDER_URI_EDITOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    IERC721Upgradeable public OVRLand;
    IMarketplace public marketplace;
    IRenting public renting;

    function initialize(IERC721Upgradeable _OVRLand) external initializer {
        __AccessControl_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __ERC721_init("OVRLand Container", "OVRLandContainer");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FOLDER_URI_EDITOR_ROLE, _msgSender());
        _setupRole(UPGRADER_ROLE, _msgSender());
        OVRLand = _OVRLand;
    }

    event ContainerCreated(
        uint256 indexed containerId,
        address indexed creator,
        uint256 timestamp
    );
    event ContainerDeleted(
        uint256 indexed containerId,
        address indexed owner,
        uint256 timestamp
    );

    //10 => 0,1,2,3,4 => 10,11,12,13,14
    //containerId => indexLands => LandId
    mapping(uint256 => mapping(uint256 => uint256)) public containerToLands;
    //landId => containerId
    mapping(uint256 => uint256) public landToContainer;
    //containerId => numberOfLands + 1 (if nLandsInContainer[256] return 4, max indexLands of container is 3 'cause it starts from 0)
    mapping(uint256 => uint256) public nLandsInContainer;
    //landId => landIndex inside container
    mapping(uint256 => uint256) public landIndex;

    /**
     * @notice verify that the caller is the owner of the container
     */
    modifier isContainerOwner(uint256 _containerId) {
        require(
            ownerOf(_containerId) == _msgSender(),
            "Caller is not the owner"
        );
        _;
    }

    /**
     * @notice verify that the lands sent aren't on renting or on selling
     */
    modifier landsFree(uint256[] memory _landId) {
        uint256 length = _landId.length;
        if (
            address(marketplace) != address(0) && address(renting) == address(0)
        ) {
            for (uint256 i = 0; i < length; i++) {
                require(
                    marketplace.landIsOnSelling(_landId[i]) == false,
                    "OVRLandContainer: One or more lands are on selling"
                );
            }
        } else if (
            address(marketplace) == address(0) && address(renting) != address(0)
        ) {
            for (uint256 i = 0; i < length; i++) {
                require(
                    renting.landIsOnRenting(_landId[i]) == false,
                    "OVRLandContainer: One or more lands are on renting"
                );
            }
        } else if (
            address(marketplace) != address(0) && address(renting) != address(0)
        ) {
            for (uint256 i = 0; i < length; i++) {
                require(
                    renting.landIsOnRenting(_landId[i]) == false,
                    "OVRLandContainer: One or more lands are on renting"
                );
                require(
                    marketplace.landIsOnSelling(_landId[i]) == false,
                    "OVRLandContainer: One or more lands are on selling"
                );
            }
        }
        _;
    }

    /**
     * @notice verify that the container sent isn't on renting or on selling
     */
    modifier containerFree(uint256 _containerId) {
        if (
            address(marketplace) != address(0) && address(renting) == address(0)
        ) {
            require(
                marketplace.containerIsOnSelling(_containerId) == false,
                "OVRLandContainer: Container is on selling"
            );
        } else if (
            address(marketplace) == address(0) && address(renting) != address(0)
        ) {
            require(
                renting.containerIsOnRenting(_containerId) == false,
                "OVRLandContainer: Container is on selling"
            );
        } else if (
            address(marketplace) != address(0) && address(renting) != address(0)
        ) {
            require(
                renting.containerIsOnRenting(_containerId) == false,
                "OVRLandContainer: Container is on selling"
            );
            require(
                marketplace.containerIsOnSelling(_containerId) == false,
                "OVRLandContainer: Container is on selling"
            );
        }

        _;
    }

    /**
     * @return owner , given a landId return the owner
     */

    function ownerOfChild(uint256 _landId) public view returns (address owner) {
        uint256 containerOfChild = landToContainer[_landId];
        address ownerAddressOfChild = ownerOf(containerOfChild);
        require(
            ownerAddressOfChild != address(0),
            "OVRLandContainer: Query for a non existing container"
        );
        return ownerAddressOfChild;
    }

    /**
     * @return lands , given a containerId return the lands inside
     */
    function childsOfParent(uint256 _containerId)
        public
        view
        returns (uint256[] memory lands)
    {
        require(
            _exists(_containerId),
            "ERC721: query for nonexistent container"
        );
        uint256 numberOfLands = nLandsInContainer[_containerId];
        uint256[] memory childs = new uint256[](numberOfLands);
        for (uint256 i = 0; i < numberOfLands; i++) {
            childs[i] = containerToLands[_containerId][i];
        }
        return childs;
    }

    /**
     * @notice function to set marketplace address, can be called only by an admin
     */
    function setMarketplaceAddress(IMarketplace _marketplace)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _marketplace != IMarketplace(address(0)),
            "Cannot be zero address"
        );
        marketplace = _marketplace;
    }

    /**
     * @notice function to set renting address, can be called only by an admin
     */
    function setRentingAddress(IRenting _renting)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_renting != IRenting(address(0)), "Cannot be zero address");
        renting = _renting;
    }

    /**
     * @notice function to create a container, it needs an array of lands
     */
    function createContainer(uint256[] memory _landId)
        public
        landsFree(_landId)
    {
        uint256 length = _landId.length;
        require(length > 1, "Cannot create container with 1 element");
        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < length; i++) {
            // It checks if token exists and is owner
            OVRLand.transferFrom(_msgSender(), address(this), _landId[i]);
            landToContainer[_landId[i]] = tokenId;
            landIndex[_landId[i]] = i;
            containerToLands[tokenId][i] = _landId[i];
        }
        nLandsInContainer[tokenId] = length;
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
        // TODO ADD SET_URI ??
        emit ContainerCreated(tokenId, _msgSender(), block.timestamp);
    }

    /**
     * @notice function to destroy a container
     */
    function deleteContainer(uint256 _containerId)
        public
        isContainerOwner(_containerId)
        containerFree(_containerId)
    {
        require(
            _exists(_containerId),
            "ERC721: query for nonexistent container"
        );
        uint256 numberOfLands = nLandsInContainer[_containerId];
        //the container doesn't exist anymore
        delete nLandsInContainer[_containerId];
        for (uint256 i = 0; i < numberOfLands; i++) {
            delete landToContainer[containerToLands[_containerId][i]];
            delete landIndex[containerToLands[_containerId][i]];

            OVRLand.transferFrom(
                address(this),
                _msgSender(),
                containerToLands[_containerId][i]
            );
            delete containerToLands[_containerId][i];
        }

        _burn(_containerId);
        emit ContainerDeleted(_containerId, _msgSender(), block.timestamp);
    }

    function addURIEditor(address _editor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(FOLDER_URI_EDITOR_ROLE, _editor);
    }

    function removeURIEditor(address _editor)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(FOLDER_URI_EDITOR_ROLE, _editor);
    }

    function addUpgrader(address _upgrader)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(UPGRADER_ROLE, _upgrader);
    }

    function removeUpgrader(address _upgrader)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(UPGRADER_ROLE, _upgrader);
    }

    function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(UPGRADER_ROLE, _admin);
        grantRole(FOLDER_URI_EDITOR_ROLE, _admin);
    }

    function removeAdminRole(address _admin)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(DEFAULT_ADMIN_ROLE, _admin);
        revokeRole(UPGRADER_ROLE, _admin);
        revokeRole(FOLDER_URI_EDITOR_ROLE, _admin);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @dev Function to set the OVRLandContainer IPFS uri.
     * @param _tokenId uint256 ID of the OVRLandContainer
     * @param _uri string of the OVRLandContainer IPFS uri
     */
    function setOVRLandContainerURI(uint256 _tokenId, string memory _uri)
        public
        onlyRole(FOLDER_URI_EDITOR_ROLE)
    {
        _setTokenURI(_tokenId, _uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
