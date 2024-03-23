// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseSetup} from "./BaseSetup.t.sol";

import "../src/Campaign.sol";

// Mock Campaign contract for testing purposes
contract MockCampaign {
    address payable public owner;
    string public description;
    uint256 public targetAmount;
    bool public active;

    constructor(address payable _owner, string memory _description, uint256 _targetAmount) {
        owner = _owner;
        description = _description;
        targetAmount = _targetAmount;
        active = true; // Assuming active by default
    }

    function deactivate() public {
        active = false;
    }
}

contract CommunityManagerTest is BaseSetup {
    function setUp() public override {
        BaseSetup.setUp();
    }

    function testDeployCommunityManager() public {
        // No assertions needed, successful deployment is implied by the test running.
    }

    function testAddManager_Valid() public {
        communityManager.addManager(manager1);

        assertTrue(communityManager.isCommunityManager(manager1));
    }

    function testAddManager_AlreadyManager() public {
        communityManager.addManager(manager1);

        vm.expectRevert("Address already a community manager");
        communityManager.addManager(manager1);
    }

    function testRemoveManager_Valid() public {
        communityManager.addManager(manager1);
        communityManager.addManager(manager2);

        communityManager.removeManager(manager1);

        assertTrue(communityManager.isCommunityManager(manager2));
        assertFalse(communityManager.isCommunityManager(manager1));
    }

    function testRemoveManager_SelfRemoval() public {
        communityManager.addManager(manager1);

        vm.expectRevert("You cannot remove yourself, please ask another manager");
        communityManager.removeManager(address(this)); // Contract as manager
    }

    function testRemoveManager_Nonexistent() public {
        communityManager.addManager(manager1);

        vm.expectRevert("Community manager not found in list");
        communityManager.removeManager(manager2);
    }

    function testAddCommunity_Valid() public {
        communityManager.addCommunity(communityId1);

        assertTrue(communityManager.isCommunityRegistered(communityId1));
    }

    function testAddCommunity_AlreadyRegistered() public {
        communityManager.addCommunity(communityId1);

        vm.expectRevert("Community already exists");
        communityManager.addCommunity(communityId1);
    }

    function testRemoveCommunity_Valid() public {
        communityManager.addCommunity(communityId1);
        communityManager.addCommunity(communityId2);

        communityManager.removeCommunity(communityId1);

        assertTrue(communityManager.isCommunityRegistered(communityId2));
        assertFalse(communityManager.isCommunityRegistered(communityId1));
    }

    function testRemoveCommunity_Nonexistent() public {
        communityManager.addCommunity(communityId1);

        vm.expectRevert("Community does not exist");
        communityManager.removeCommunity(communityId2);
    }

    function testTotalCommunities() public {
        communityManager.addCommunity(communityId1);
        communityManager.addCommunity(communityId2);

        assertEq(communityManager.totalCommunities(), 2);
    }

    function testListCommunities() public {
        communityManager.addCommunity(communityId1);
        communityManager.addCommunity(communityId2);

        uint64[] memory actualList = communityManager.listCommunity();

        uint256 expectedLength = 2;
        assertEq(actualList.length, expectedLength);
        assertTrue(actualList[0] == communityId1 || actualList[0] == communityId2); // Order not guaranteed
        assertTrue(actualList[1] == communityId1 || actualList[1] == communityId2); // Order not guaranteed
    }

    function testIsCommunityManager_ValidManager() public {
        communityManager.addManager(manager1);

        assertTrue(communityManager.isCommunityManager(manager1));
    }

    function testIsCommunityManager_Owner() public {
        assertTrue(communityManager.isCommunityManager(manager1));
    }

    function testIsCommunityManager_NonManager() public {
        assertFalse(communityManager.isCommunityManager(address(10))); // Random address
    }

    // -------------------

    function testAddCommunity_CampaignAllowed() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        assertTrue(community.canCreateCampaign(communityId1));
    }

    function testAddCampaign_NotCommunityOwner() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        vm.expectRevert("Only Community Owner can call this function");
        community.addCampaign{value: 1 ether}(communityId1, "Campaign 1", 1 ether);
    }

    function testAddCampaign_DisallowedCampaigns() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", false, 0);

        vm.expectRevert("Community does not allow campaign creation");
        community.addCampaign{value: 1 ether}(communityId1, "Campaign 1", 1 ether);
    }

    // Mock the Campaign contract for interaction tests
    function testAddCampaign_Success(MockCampaign campaign) public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);
        communityOwner1 = communityOwner1; // Simulate correct access for restricted function

        // Deploy the mock campaign
        // campaign = new MockCampaign(communityOwner1, "Campaign 1", 1 ether);

        // community.addCampaign{value: 1 ether}(communityId1, campaign.description, campaign.targetAmount);

        // // Assert raised amount in Community and campaign details
        // assertEq(community.community(communityId1).raisedAmount, 1 ether);
        // assertEq(address(campaign), community.community(communityId1).currentCampaign);
    }

    // -------------------

    // function testSetCommunityManagerOK() public {
    //     vm.startPrank(manager);

    //     communityManager.setCommunityManager(payable(alice), true); // Set with owner privileges
    //     vm.stopPrank();

    //     assertEq(communityManager.getCommunityManagerWallet(), alice);
    // }

    // function testSetCommunityManagerNOK() public {
    //     vm.startPrank(hackUser);
    //     vm.expectRevert("Only Community Manager or Owner can perform this action");
    //     communityManager.setCommunityManager(hackUser, true); // Try setting from non-owner
    //     vm.stopPrank();

    //     assertEq(communityManager.getCommunityManagerWallet(), manager);
    // }

    // function testAddCommunity() public {
    //     uint24 initialCommunityCount = communityManager.totalCommunities();

    //     // // vm.expectEmit(communityManager, "CommunityAdded", _community);

    //     // communityManager.addCommunity(_community);
    //     community = communityManager.addCommunity(
    //         1003, "comunidate3", "A segunda maiou comunidade para teste", community2owner1
    //     );

    //     assertEq(communityManager.totalCommunities(), initialCommunityCount + 1);
    //     // bool isActive = CommunityManager(diamond).isActive();
    //     // assertEq(isActive, true);
    // }

    // function testRestrictNonOwnerSetCommunityManager() public {
    //     // address randomAddress = address(1); // Arbitrary non-owner/manager address

    //     // vm.expectRevert("Only Community Manager or Owner can perform this action");
    //     // manager.setCommunityManager(randomAddress); // Try setting from non-owner/manager
    // }

    // Future Add more tests for other Community contract functions...
}
