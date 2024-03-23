// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseSetup} from "./BaseSetup.t.sol";

import {Campaign} from "../src/Campaign.sol";
import "forge-std/console.sol";

contract CampaignTest is BaseSetup {
    function setUp() public override {
        BaseSetup.setUp();
    }

    function testAddCampaign_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        (
            uint64 retrievedCommunityId,
            address retrievedOwner,
            string memory retrievedDescription,
            uint256 retrievedTargetAmount,
            uint256 retrievedRaisedAmount,
            uint256 retrievedFeeAmount,
            uint256 retrievedComissionAmount,
            bool retrievedActive
        ) = campaign.GetCampaing(campaignId);

        assertEq(retrievedCommunityId, communityId);
        assertEq(retrievedOwner, communityOwner1);
        assertEq(retrievedDescription, description);
        assertEq(retrievedTargetAmount, targetAmount);
        assertEq(retrievedRaisedAmount, 0);
        assertEq(retrievedFeeAmount, 0);
        assertEq(retrievedComissionAmount, 0);
        assertTrue(retrievedActive);
    }

    function testAddCampaign_AlreadyExists() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        vm.expectRevert("Campaign with this ID already exists");
        campaign.AddCampaing(campaignId, communityOwner1, communityId, "Another Description", targetAmount);
    }

    function testRemoveCampaign_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        campaign.RemoveCampaing(campaignId);

        vm.expectRevert("Campaign does not exist");
        campaign.GetCampaing(campaignId);
    }

    function testRemoveCampaign_Nonexistent() public {
        vm.expectRevert("Campaign does not exist");
        campaign.RemoveCampaing(campaignId);
    }

    function testDonate_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        deal(msg.sender, 0.5 ether);
        campaign.donate{value: 0.5 ether}(campaignId);

        (uint256 raisedAmount,,,,,,,) = campaign.GetCampaing(campaignId);

        assertEq(raisedAmount, 0.5 ether);
    }

    function testDonate_MinimumPaymentNotAchieved() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        vm.expectRevert("MinimunToPayNotAchieved");
        campaign.donate{value: 0.001 ether}(campaignId);
    }

    function testWithdrawFunds_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        deal(msg.sender, 0.5 ether);
        campaign.donate{value: 0.5 ether}(campaignId);

        campaign.setActive(campaignId); // Make campaign inactive for withdrawal

        // Simulate campaign communityOwner1 calling withdrawFunds
        campaign.withdrawFunds(campaignId);

        uint256 ownerBalance = address(communityOwner1).balance;
        assertEq(ownerBalance, 0.5 ether); // Expect communityOwner1 to receive raised amount
    }

    function testWithdrawFunds_NotCampaignOwner() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        deal(msg.sender, 0.5 ether);
        campaign.donate{value: 0.5 ether}(campaignId);

        campaign.setActive(campaignId); // Make campaign inactive for withdrawal

        vm.expectRevert("Only Campaign Owner can call this function");
        campaign.withdrawFunds(campaignId); // Not campaign communityOwner1
    }

    function testWithdrawFunds_CampaignActive() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        deal(msg.sender, 0.5 ether);
        campaign.donate{value: 0.5 ether}(campaignId);

        vm.expectRevert("Campaign must be inactive to withdraw funds");
        campaign.withdrawFunds(campaignId); // Campaign still active
    }

    function testWithdrawFunds_NoFunds() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        campaign.setActive(campaignId); // Make campaign inactive for withdrawal

        vm.expectRevert("Campaign have no funds to transfer");
        campaign.withdrawFunds(campaignId); // No funds donated
    }

    function testTransferToCommunityFunds_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        deal(msg.sender, 0.5 ether);
        campaign.donate{value: 0.5 ether}(campaignId);

        campaign.setActive(campaignId); // Make campaign inactive for transfer

        campaign.transferToCommunityFunds(campaignId);

        // Mock functionality to check Community contract received funds (if applicable)
    }

    function testTransferToCommunityFunds_NotCampaignOwner() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        deal(msg.sender, 0.5 ether);
        campaign.donate{value: 0.5 ether}(campaignId);

        campaign.setActive(campaignId); // Make campaign inactive for transfer

        vm.expectRevert("Only Campaign Owner can call this function");
        campaign.transferToCommunityFunds(campaignId); // Not campaign communityOwner1
    }

    function testTransferToCommunityFunds_CampaignActive() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        deal(msg.sender, 0.5 ether);
        campaign.donate{value: 0.5 ether}(campaignId);

        vm.expectRevert("Campaign must be inactive to withdraw funds");
        campaign.transferToCommunityFunds(campaignId); // Campaign still active
    }

    function testTransferToCommunityFunds_NoFunds() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        campaign.setActive(campaignId); // Make campaign inactive for transfer

        vm.expectRevert("Campaign have no funds to transfer");
        campaign.transferToCommunityFunds(campaignId); // No funds donated
    }

    function testCloseCampaign_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        campaign.closeCampaign(campaignId);

        (,,,,,,, bool isActive) = campaign.GetCampaing(campaignId);
        assertFalse(isActive);
    }

    function testCloseCampaign_NotCampaignOwner() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        vm.expectRevert("Only Campaign Owner can call this function");
        campaign.closeCampaign(campaignId); // Not campaign communityOwner1
    }

    function testCloseCampaign_AlreadyInactive() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        campaign.closeCampaign(campaignId);

        vm.expectRevert("Campaign must be active to allow closure");
        campaign.closeCampaign(campaignId); // Already closed
    }

    function testSetActive_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        campaign.closeCampaign(campaignId); // Close campaign

        campaign.setActive(campaignId);

        (,,,,,,, bool isActive) = campaign.GetCampaing(campaignId);
        assertTrue(isActive);
    }

    function testSetActive_NotCampaignOwner() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        vm.expectRevert("Only Campaign Owner can call this function");
        campaign.setActive(campaignId); // Not campaign communityOwner1
    }

    function testIsCampaignOwner_Valid() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        bool isOwner = campaign.isCampaignOwner(communityOwner1, campaignId);
        assertTrue(isOwner);
    }

    function testIsCampaignOwner_NotOwner() public {
        string memory description = "Test Campaign";
        uint256 targetAmount = 1 ether;

        campaign.AddCampaing(campaignId, communityOwner1, communityId, description, targetAmount);

        bool isOwner = campaign.isCampaignOwner(manager, campaignId);
        assertFalse(isOwner);
    }

    function testGetBalance_Valid() public {
        deal(msg.sender, 1 ether);
        uint256 balance = campaign.getBalance();
        assertEq(balance, 1 ether);
    }

    // function testCreateCampaign() public {
    //     Campaign campaign2;
    //     uint256 targetAmount = 10 ether;

    //     vm.startPrank(communityOwner2);
    //     campaign2 = community2.addCampaign{value: 0.0005 ether}("Mega campanha 2024 para teste isolado", targetAmount);

    //     // vm.expectEmit(campaign, "CampaignCreated", creator, address(community), targetAmount);

    //     // Campaign.CampaignData memory campaignData = campaign2.campaigns(address(campaign2));

    //     // Campaign.CampaignData memory campaignData = campaign2.campaigns[address(campaign2)];

    //     assertTrue(campaign2.active());
    //     // console.log("This is a simple message");
    //     assertEq(campaign2.communityOwner1(), communityOwner2);
    //     assertEq(campaign2.community(), address(community2));
    //     assertEq(campaign2.targetAmount(), targetAmount);
    //     assertEq(campaign2.raisedAmount(), 0);

    //     vm.stopPrank();
    // }

    // function testDonate() public {
    //     uint256 donationAmount = 0.1 ether;
    //     uint256 tax = donationAmount * 1 / 1000;
    //     uint256 initialCondition = campaign.raisedAmount();
    //     uint256 feeStorage = 100000;
    //     uint256 expectedRaisedAmount = donationAmount - tax + initialCondition - feeStorage;

    //     vm.startPrank(donor1);
    //     // vm.expectEmit(campaign, "DonationReceived", donor, donationAmount);

    //     campaign.donate{value: donationAmount}();

    //     // payable(campaignAddress).transfer(donationAmount);

    //     vm.stopPrank();

    //     // Campaign.CampaignData memory campaignData = campaign.campaigns(campaignAddress);
    //     assertEq(campaign.raisedAmount(), expectedRaisedAmount);
    // }

    // function testDirectDonate_Fail() public {
    //     uint256 donationAmount = 0.1 ether;
    //     // error CampaignPaymmentMustUseDonateFunction;
    //     // uint256 tax = donationAmount * 1 / 1000;
    //     // uint256 expectedRaisedAmount = donationAmount - tax;

    //     vm.startPrank(donor1);
    //     // vm.expectEmit(campaign, "DonationReceived", donor, donationAmount);
    //     // campaign.donate(donationAmount);

    //     vm.expectRevert(0xeb178cbf);
    //     payable(address(campaign)).transfer(donationAmount);

    //     vm.stopPrank();

    //     // Campaign.CampaignData memory campaignData = campaign.campaigns(campaignAddress);
    //     // assertEq(campaign.raisedAmount(), expectedRaisedAmount);
    // }

    // function testWithdrawFunds_InactiveCampaign() public {
    //     vm.startPrank(communityOwner1);

    //     vm.expectRevert("Campaign must be inactive to withdraw funds");
    //     campaign.withdrawFunds();

    //     vm.stopPrank();
    // }

    // function testDeacivateCampaign_Success() public {
    //     vm.startPrank(communityOwner1);

    //     assertTrue(campaign.active());
    //     campaign.closeCampaign();

    //     assertFalse(campaign.active());

    //     vm.stopPrank();
    // }

    // function testWithdrawFunds_FailOwner() public {
    //     vm.expectRevert("Only Campaign Owner can call this function");
    //     campaign.withdrawFunds();
    // }

    // function testWithdrawFunds_Success() public {
    //     vm.startPrank(communityOwner1);

    //     campaign.closeCampaign();
    //     uint256 initialBalance = address(communityOwner1).balance;

    //     console.log(address(campaign).balance);
    //     console.log(initialBalance);
    //     console.log(campaign.raisedAmount());

    //     uint256 raisedAmount = campaign.raisedAmount();

    //     campaign.withdrawFunds();
    //     console.log(address(campaign).balance);

    //     assertEq(address(communityOwner1).balance, initialBalance + raisedAmount);

    //     vm.stopPrank();
    // }

    // function testTransferToCommunityFunds_Success() public {
    //     vm.startPrank(communityOwner1);

    //     campaign.closeCampaign();
    //     uint256 initialBalance = address(community).balance;

    //     console.log(address(campaign).balance);
    //     console.log(address(community).balance);
    //     uint256 raisedAmount = campaign.raisedAmount();

    //     campaign.transferToCommunityFunds();
    //     console.log(address(campaign).balance);

    //     assertEq(address(community).balance, initialBalance + raisedAmount);

    //     vm.stopPrank();
    // }

    // Add more tests for transferToCommunityFunds and setIsActive...
}
