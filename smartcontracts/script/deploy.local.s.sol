// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
// import {Counter} from "../src/Counter.sol";

import {Campaign} from "../src/Campaign.sol";
import {Community} from "../src/Community.sol";
import {CommunityManager} from "../src/CommunityManager.sol";

contract Local is Script {
    // Counter counter;
    Campaign campaign;
    CommunityManager communityManager;
    Community community;

    address manager = 0x5fc7Bb8eBE8316B88390A10370fe1DA2FA481734;
    address communityOwner1 = 0x22F7d0aa47F75D2D4Df9D6c8867117941Cbf4bf3;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);

        // counter = new Counter();
        // console2.log("Counter address: ", address(counter));

        communityManager = new CommunityManager(payable(manager));
        communityManager.setDiamond(manager);

        // communityManager = new CommunityManager(payable(manager));
        console2.log("Counter address: ", address(communityManager));

        community = new Community();
        community.setDiamond(manager);
        // community = communityManager.addCommunity(1001, "comunidate Web3", "A melhor comunidade", communityOwner1);
        console2.log("Counter address: ", address(community));

        campaign = new Campaign(address(community));
        campaign.setDiamond(manager);
        // vm.prank(communityOwner1);
        // campaign = community.addCampaign{value: 0.00005 ether}("Super campanha 2024 para aprendizado em Web3", 5 ether);
        console2.log("Counter address: ", address(campaign));
        // vm.stopPrank();

        vm.stopBroadcast();
    }
}
