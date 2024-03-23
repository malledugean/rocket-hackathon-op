// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Campaign} from "../src/Campaign.sol";
import {CommunityManager} from "../src/CommunityManager.sol";
import {Community} from "../src/Community.sol";
import {Donor} from "../src/Donor.sol";
import {Diamond} from "../src/Diamond.sol";
import {Utils} from "./Utils.t.sol";

contract BaseSetup is Utils {
    Diamond diamond;
    CommunityManager communityManager;
    Community community;
    Campaign campaign;
    Donor donation;

    uint64 communityId;
    uint64 campaignId;
    uint64 communityId1;
    uint64 communityId2;

    address[] _users;
    address controller;
    address alice;
    address bob;
    address eve;
    address trent;
    address communityOwner1;
    address communityOwner2;
    address payable manager;
    address donor1;
    address hackUser;
    address zero;

    address manager1;
    address manager2;

    function setUp() public virtual {
        _users = createUsers(10);

        controller = _users[0];
        alice = _users[1];
        bob = _users[2];
        eve = _users[3];
        trent = _users[4];
        zero = address(0x0);
        communityOwner1 = _users[5];
        communityOwner2 = _users[6];
        manager = payable(_users[7]);
        donor1 = _users[8];
        hackUser = _users[9];
        manager1 = _users[10];
        manager2 = _users[911];

        communityId = 1001;
        campaignId = 1001;

        communityId1 = 100;
        communityId2 = 200;

        vm.label(controller, "CONTROLLER");
        vm.label(alice, "ALICE");
        vm.label(bob, "BOB");
        vm.label(eve, "EVE");
        vm.label(trent, "TRENT");
        vm.label(zero, "ZERO");
        vm.label(communityOwner1, "Baixada Sul educa");
        vm.label(communityOwner2, "ZL na educacao");
        vm.label(manager, "TF Boss");
        vm.label(donor1, "Big Heart");
        vm.label(hackUser, "Bunny");

        vm.startPrank(controller);
        donation = new Donor();
        communityManager = new CommunityManager(manager);
        communityManager.setDiamond(manager);

        community = new Community();
        community.setDiamond(manager);

        campaign = new Campaign(address(community));
        campaign.setDiamond(manager);
        // communityManager.addCommunity(1001, "comunidate1", "A melhor comunidade para teste", communityOwner1);
        // community2 =
        //     communityManager.addCommunity(1002, "comunidate2", "A maior comunidade para teste", communityOwner2);
        vm.stopPrank();

        vm.startPrank(communityOwner1);
        // campaign = community.addCampaign{value: 0.0001 ether}("Super campanha 2024 para teste", 5 ether);
        vm.stopPrank();

        vm.startPrank(donor1);
        // campaign.donate{value: 1 ether}();

        vm.stopPrank();
    }

    function test_basesetup_just_for_pass_in_converage() public {}
}
