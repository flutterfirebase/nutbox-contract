// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '../interfaces/ITrustAssetHandler.sol';
import '../interfaces/IRegistryHub.sol';
import '../ERC20Helper.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20AssetHandler is ITrustAssetHandler, ERC20Helper, AccessControl {
    using SafeMath for uint256;

    address public registryHub;

    // contract => hasWhitelisted
    mapping (address => bool) private whiteList;
    // source => amount
    mapping (bytes32 => uint256) private depositBalance;

    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");

    event WhitelistManagerAdded(address manager);
    event WhitelistManagerRemoved(address manager);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender is not admin");
        _;
    }

    modifier onlyAdminOrWhitelistManager() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(WHITELIST_MANAGER_ROLE, msg.sender),
            "Sender is not admin or in whitelist manager group");
        _;
    }

    constructor(address _registryHub) public {
        require(_registryHub != address(0), 'Invalid registry hub address');
        registryHub = _registryHub;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(WHITELIST_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setRegistryHub(address _registryHub) public onlyAdmin {
        require(_registryHub != address(0), 'Invalid registry hub address');
        registryHub = _registryHub;
    }

    function adminAddWhitelistManager(address _manager) public onlyAdmin {
        require(!hasRole(WHITELIST_MANAGER_ROLE, _manager), "Address already in the whitelist manager group");
        grantRole(WHITELIST_MANAGER_ROLE, _manager);
        emit WhitelistManagerAdded(_manager);
    }

    function adminRemoveWhitelistManager(address _manager) public onlyAdmin {
        require(hasRole(WHITELIST_MANAGER_ROLE, _manager), "Address not in the whitelist manager group");
        revokeRole(WHITELIST_MANAGER_ROLE, _manager);
        emit WhitelistManagerRemoved(_manager);
    }

    function setWhiteList(address _contract) public onlyAdminOrWhitelistManager {
        require(_contract != address(0), 'Invalid contract address');
        whiteList[_contract] = true;
    }

    function lockOrBurnAsset(bytes32 source, bytes32 assetId, address depositer, uint256 amount) override external {
        require(whiteList[msg.sender], 'Permission denied: contract is not white list');

        address tokenAddress = IRegistryHub(registryHub).getHomeLocation(assetId);
        if (IRegistryHub(registryHub).mintable(assetId)) {
            burnERC20(tokenAddress, depositer, amount);
        } else {
            lockERC20(tokenAddress, depositer, address(this), amount);
            depositBalance[source] = depositBalance[source].add(amount);
        }
    }

    function lockAsset(bytes32 source, bytes32 assetId, address depositer, uint256 amount) external {
        require(whiteList[msg.sender], 'Permission denied: contract is not white list');

        address tokenAddress = IRegistryHub(registryHub).getHomeLocation(assetId);
        lockERC20(tokenAddress, depositer, address(this), amount);
        depositBalance[source] = depositBalance[source].add(amount);
    }

    function unlockOrMintAsset(bytes32 source, bytes32 assetId, address recipient, uint256 amount) override external {
        require(whiteList[msg.sender], 'Permission denied: contract is not white list');

        address tokenAddress = IRegistryHub(registryHub).getHomeLocation(assetId);
        if (IRegistryHub(registryHub).mintable(assetId)) {
            mintERC20(tokenAddress, address(recipient), amount);
        } else {
            require(depositBalance[source] >= amount, 'Insufficient deposited asset balance');
            releaseERC20(tokenAddress, address(recipient), amount);
            depositBalance[source] = depositBalance[source].sub(amount);
        }
    }

    function unlockAsset(bytes32 source, bytes32 assetId, address recipient, uint256 amount) external {
        require(whiteList[msg.sender], 'Permission denied: contract is not white list');
        require(depositBalance[source] >= amount, 'Insufficient deposited asset balance');

        address tokenAddress = IRegistryHub(registryHub).getHomeLocation(assetId);
        releaseERC20(tokenAddress, address(recipient), amount);
        depositBalance[source] = depositBalance[source].sub(amount);
    }

    function getBalance(bytes32 source) view external returns(uint256) {
        return depositBalance[source];
    }
}