// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.18;

struct Donation {
    address donor;
    uint256 amount;
    uint256 timestamp; // Year of donation
}

struct ExpenseReport {
    // Mapping of expense category (string) to its amount (uint256)
    mapping(string => uint256) expenses;
    // Optional additional data (e.g., receipts, descriptions)
    string[] reportData;
    // Approvals mapping (address of approver to bool indicating approval)
    mapping(address => bool) approvals;
}

struct CommunityData {
    uint64 id;
    string name;
    string description;
    bool allowedCampaign;
    uint8 campaignId;
    mapping(address => bool) approvedExpenses; // Mapping of approved expense addresses
    mapping(uint256 => ExpenseReport) expenseReports;
    uint256 raisedAmount;
    uint256 feeAmount;
    uint256 commisionAmount;
    mapping(address => bool) communityOwners;
}

struct CampaignData {
    address owner;
    uint64 communityId;
    string description;
    uint256 targetAmount;
    uint256 raisedAmount;
    uint256 feeAmount;
    uint256 commisionAmount;
    bool active;
}
