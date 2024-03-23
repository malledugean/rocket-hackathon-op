// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.18;

import "./BaseFacet.sol";
import "./Community.sol";

import "./Structs.sol";

contract CommunityManager is BaseFacet {
    error CommuntyAlredyRegistered();

    mapping(address => bool) public communityManagers;
    address[] public communityManagerList;

    uint24 private communitiesCount;

    mapping(uint64 => Community) public communities;
    mapping(uint64 => bool) public communityRegistered;
    uint64[] public communityList;

    /**
     * @dev Constructor that takes the manager and initializes the CommunityManager.
     * @param _manager Address of manager.
     */
    constructor(address payable _manager) {
        communitiesCount = 0;

        communityManagers[_manager] = true;
        communityManagerList.push(_manager);
    }

    function addManager(address _newManager) public onlyCommunityManager {
        require(!communityManagers[_newManager], "Address already a community manager");

        communityManagers[_newManager] = true;
        communityManagerList.push(_newManager);
    }

    function removeManager(address _oldManager) public onlyCommunityManager {
        require(communityManagers[_oldManager], "Address not a community manager");
        require(_oldManager != msg.sender, "You cannot remove yourself, please ask another manager");

        // Find the index of the address in the list
        uint256 index = 0;
        while (index < communityManagerList.length && communityManagerList[index] != _oldManager) {
            index++;
        }

        require(index < communityManagerList.length, "Community manager not found in list");

        // Shift elements to remove the address at the found index
        for (uint256 i = index; i < communityManagerList.length - 1; i++) {
            communityManagerList[i] = communityManagerList[i + 1];
        }

        // Reduce the array size by 1 (optional, for gas optimization)
        communityManagerList.pop();

        delete communityManagers[_oldManager]; // Delete from mapping
    }

    function listManager() public view returns (address[] memory) {
        return communityManagerList;
    }

    function addCommunity(uint64 _newCommunityId) public onlyCommunityManager {
        require(!communityRegistered[_newCommunityId], "Community already exists");

        communityList.push(_newCommunityId);
        communitiesCount++;
        communityRegistered[_newCommunityId] = true;
    }

    function removeCommunity(uint64 _communityId) public onlyCommunityManager {
        require(communityRegistered[_communityId], "Community does not exist");

        // Find the index of the ID in the list
        uint256 index = 0;
        while (index < communityList.length && communityList[index] != _communityId) {
            index++;
        }

        require(index < communityList.length, "Community ID not found in list");

        // Shift elements to remove the ID at the found index
        for (uint256 i = index; i < communityList.length - 1; i++) {
            communityList[i] = communityList[i + 1];
        }

        // Reduce the array size by 1 (optional, for gas optimization)
        communityList.pop();

        communitiesCount--;
        communityRegistered[_communityId] = false;
    }

    function listCommunity() public view returns (uint64[] memory) {
        return communityList;
    }

    /**
     * @dev Allows the Diamond contract (owner) to set a community manager.
     * @param _manager Address of the community manager.
     * @param _isManager Boolean indicating community manager status (True for manager, False otherwise).
     */
    function setCommunityManager(address _manager, bool _isManager) external onlyCommunityManager {
        if (_isManager) {
            addManager(_manager);
        } else {
            removeManager(_manager);
        }
    }

    /**
     * @dev This function retrieves the total number of registered communities within the system.
     *
     * This value represents the count of communities that have been created and potentially managed
     * through the Community Manager contract or related functionalities.
     *
     * @return uint24 The total number of registered communities (capped at 2**24 - 1).
     *
     * Note:
     *
     * - The return value is limited to `uint24` (maximum value of 2**24 - 1) to optimize storage usage.
     */
    function totalCommunities() public view returns (uint24) {
        return communitiesCount;
    }

    /**
     * @dev This function retrieves the address of the currently set Community Manager.
     *
     * This address is expected to be payable, meaning it can receive Ether payments.
     * The Community Manager is responsible for various community-related tasks within the ecosystem.
     *
     * @return address payable The address of the community manager wallet.
     *
     */
    function getCommunityManagerWallet() external view returns (address payable) {
        return payable(diamond);
    }

    /**
     * @dev Checks if an address is a community manager.
     * @param _manager Address to check.
     * @return True if the address is a community manager, False otherwise.
     */
    function isCommunityManager(address _manager) public view returns (bool) {
        bool result = false;
        if (communityManagers[_manager] || msg.sender == diamond) {
            result = true;
        }
        return result;
    }

    // function addCommunity(uint64 _id, string memory _name, string memory _description, address _communityOwner)
    //     public
    //     returns (Community)
    // {
    //     Community newCommunity = new Community(_id, _name, _description, _communityOwner);
    //     if (isCommunityRegistered(_id)) {
    //         // Community is already registered
    //         revert CommuntyAlredyRegistered();
    //     } else {
    //         communityList.push(_id);
    //         communitiesCount++;
    //     }

    //     return newCommunity;
    // }

    function isCommunityRegistered(uint64 _id) public view returns (bool) {
        bool result = communityRegistered[_id];
        return result;
    }

    function getComunities() public view returns (uint64[] memory) {
        uint64[] memory list = communityList;
        return list;
    }

    /**
     * @dev Modifier to restrict function calls to the Community Manager contract.
     */
    modifier onlyCommunityManager() {
        require(isCommunityManager(msg.sender), "Only Community Manager or Owner can perform this action");
        _;
    }

    /**
     * @dev It should return an array of function selectors
     * for all the public functions exposed by the facet.
     *
     * The Diamond contract uses this function to identify which facet to
     * delegate function calls to based on the function selector (first four bytes
     * of the function signature).
     *
     * @return bytes4[] memory An array containing the function selectors of the facet.
     */
    function functionSelectors() public pure override returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](4); // Adjust the number based on your functions

        selectors[0] = CommunityManager.setCommunityManager.selector;

        selectors[1] = CommunityManager.getCommunityManagerWallet.selector;

        // ... Add selectors for other public functions in CommunityManagerFacet

        return selectors;
    }
}
