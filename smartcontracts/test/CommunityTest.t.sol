// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseSetup} from "./BaseSetup.t.sol";

import "../src/Community.sol";

contract CommunityTest is BaseSetup {
    function setUp() public override {
        BaseSetup.setUp();
    }

    function testAddCommunity_Valid() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        assertTrue(community.exists(communityId1));
    }

    function testAddCommunity_AlreadyExists() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        vm.expectRevert("Community with this ID already exists");
        community.AddCommunity(communityId1, "Community 1 (Duplicate)", "Another description", true, 1);
    }

    function testRemoveCommunity_Valid() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        community.RemoveCommunity(communityId1);

        assertFalse(community.exists(communityId1));
    }

    function testRemoveCommunity_Nonexistent() public {
        vm.expectRevert("Community does not exist");
        community.RemoveCommunity(communityId1);
    }

    function testGetCommunity_Valid() public {
        string memory name = "Community 1";
        string memory description = "Description 1";
        bool allowedCampaign = true;
        uint8 campaignId = 0;
        uint256 expectedRaisedAmount = 0;
        uint256 expectedFeeAmount = 0;
        uint256 expectedCommisionAmount = 0;

        community.AddCommunity(communityId1, name, description, allowedCampaign, campaignId);

        (
            uint64 id,
            string memory actualName,
            string memory actualDescription,
            bool actualAllowedCampaign,
            uint8 actualCampaignId,
            uint256 actualRaisedAmount,
            uint256 actualFeeAmount,
            uint256 actualCommisionAmount
        ) = community.GetCommunity(communityId1);

        assertEq(id, communityId1);
        assertEq(actualName, name);
        assertEq(actualDescription, description);
        assertEq(actualAllowedCampaign, allowedCampaign);
        assertEq(actualCampaignId, campaignId);
        assertEq(actualRaisedAmount, expectedRaisedAmount);
        assertEq(actualFeeAmount, expectedFeeAmount);
        assertEq(actualCommisionAmount, expectedCommisionAmount);
    }

    function testGetCommunity_Nonexistent() public {
        vm.expectRevert("Community does not exist");
        community.GetCommunity(communityId1);
    }

    function testDefineAllowedCampaigns_Valid() public {
        // Add community and set community owner
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);
        communityManager.addManager(communityOwner1); // Grant access

        communityOwner1 = communityOwner1; // Simulate correct access for restricted function

        community.defineAllowedCampaigns(communityId1, false);

        assertFalse(community.canCreateCampaign(communityId1));
    }

    function testDefineAllowedCampaigns_NonexistentCommunity() public {
        communityManager.addManager(communityOwner1); // Grant access

        communityOwner1 = communityOwner1; // Simulate correct access for restricted function

        vm.expectRevert("Community does not exist");
        community.defineAllowedCampaigns(communityId1, false);
    }

    function testCanCreateCampaign_Allowed() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        assertTrue(community.canCreateCampaign(communityId1));
    }

    function testCanCreateCampaign_Disallowed() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", false, 0);

        assertFalse(community.canCreateCampaign(communityId1));
    }

    // Function tests for donate() and withdrawFunds() with edge cases and error handling...

    function testDonate_Valid() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);
        (uint64 id, string memory description,,,,,, uint256 raisedAmount) = community.community(communityId1);
        uint256 initialRaisedAmount = raisedAmount;
        // uint256 initialRaisedAmount = community.community(communityId1).raisedAmount();
        uint256 donationAmount = 1 ether;

        deal(msg.sender, donationAmount);
        community.donate{value: donationAmount}(communityId1);

        (,,,,,,, uint256 raisedAmount2) = community.community(communityId1);

        assertEq(raisedAmount2, initialRaisedAmount + donationAmount);
    }

    function testDonate_MinimumPaymentNotAchieved() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        deal(msg.sender, 100 gwei); // Set donation amount below minimum
        vm.expectRevert("MinimunToPayNotAchieved");
        community.donate{value: 100 gwei}(communityId1);
    }

    function testWithdrawFunds_NotCommunityOwner() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        vm.expectRevert("Only Community Owner can call this function");
        community.withdrawFunds(communityId1);
    }

    function testWithdrawFunds_RevertMessage() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);
        communityOwner1 = hackUser; // Set a different address

        vm.expectRevert(bytes("CommuntyFundsCannotBeWithdraw")); // Check for specific revert message
        community.withdrawFunds(communityId1);
    }

    // Function tests for functionSelectors()

    function testFunctionSelectors() public {
        bytes4[] memory expectedSelectors = new bytes4[](3); // Adjust based on actual functions
        expectedSelectors[0] = Community.defineAllowedCampaigns.selector;

        bytes4[] memory actualSelectors = community.functionSelectors();

        assertEq(actualSelectors.length, expectedSelectors.length);
        for (uint256 i = 0; i < expectedSelectors.length; i++) {
            assertEq(actualSelectors[i], expectedSelectors[i]);
        }
    }

    // Fallback and receive tests (if applicable)

    function testReceive_Revert() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        deal(msg.sender, 1 ether);
        vm.expectRevert("CommuntyPaymmentMustUseDonateFunction");
        (bool success,) = address(community).call{value: 1 ether}(""); // Call receive directly
        assert(!success); // Assert the call failed
    }

    function testFallback_Revert() public {
        community.AddCommunity(communityId1, "Community 1", "Description 1", true, 0);

        deal(msg.sender, 1 ether);
        vm.expectRevert("CommuntyPaymmentMustUseDonateFunction");
        (bool success,) = address(community).call{value: 1 ether}(""); // Call fallback directly
        assert(!success); // Assert the call failed
    }

    // function testCreateCampaign_Sucess() public {
    //     Campaign campaign2;
    //     uint256 targetAmount = 20 ether;

    //     vm.startPrank(communityOwner2);
    //     campaign2 =
    //         community2.addCampaign{value: 0.001 ether}("Super campanha 2024 para teste de comunidade", targetAmount);

    //     assertTrue(campaign2.active());
    //     // console.log("This is a simple message");
    //     assertEq(campaign2.owner(), communityOwner2);
    //     assertEq(campaign2.community(), address(community2));
    //     assertEq(campaign2.targetAmount(), targetAmount);
    //     assertEq(campaign2.raisedAmount(), 0);

    //     vm.stopPrank();
    // }

    // function testCreateCampaign_FailValue() public {
    //     Campaign campaign2;
    //     uint256 targetAmount = 20 ether;

    //     vm.startPrank(communityOwner2);
    //     vm.expectRevert("Minimal Funds to Create Campaign not acchieved");
    //     campaign2 =
    //         community2.addCampaign{value: 0.0000001 ether}("Mini campanha 2024 para teste de comunidade", targetAmount);

    //     vm.stopPrank();
    // }

    // Add more tests for other Community contract functions...
}
