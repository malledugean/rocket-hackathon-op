// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.18;

import "./BaseFacet.sol";
import "./CommunityManager.sol";
import "./Campaign.sol";

import "./Structs.sol";

contract Community is BaseFacet {
    error CampaignAlredyCreated();
    error CommuntyFundsCannotBeWithdraw();
    error CommuntyPaymmentMustUseDonateFunction();
    error MinimunToPayNotAchieved();

    event Log(uint256 gas);

    uint256 public raisedAmountAcc;
    uint256 public feeAmountAcc;
    uint256 public commisionAmountAcc;

    mapping(uint64 => CommunityData) public community;

    /**
     * @dev Constructor that takes the name and description and initializes the Community.
     */
    constructor() {
        creator = msg.sender;
    }

    function AddCommunity(
        uint64 _id,
        string memory _name,
        string memory _description,
        bool _allowedCampaign,
        uint8 _campaignId
    ) public {
        require(!(community[_id].id > 0), "Community with this ID already exists");

        // community[_id] = CommunityData(0, _name, _description, _allowedCampaign, _campaignId, 0, 0, 0); // Initialize directly in storage

        // community[_id] = CommunityData({
        //     id: _id,
        //     name: _name,
        //     description: _description,
        //     allowedCampaign: _allowedCampaign,
        //     campaignId: _campaignId,
        //     raisedAmount: 0,
        //     feeAmount: 0,
        //     commisionAmount: 0
        // });

        community[_id].id = _id; // Initialize fields individually
        community[_id].name = _name;
        community[_id].description = _description;
        community[_id].allowedCampaign = _allowedCampaign;
        community[_id].campaignId = _campaignId;
        community[_id].raisedAmount = 0;
        community[_id].feeAmount = 0;
        community[_id].commisionAmount = 0;
    }

    function exists(uint64 _id) public view returns (bool) {
        return community[_id].id > 0; // Check if ID field in CommunityData is greater than 0
    }

    function RemoveCommunity(uint64 _id) public {
        require(exists(_id), "Community does not exist");
        delete community[_id];
    }

    function GetCommunity(uint64 _id)
        public
        view
        returns (uint64, string memory, string memory, bool, uint8, uint256, uint256, uint256)
    {
        require(exists(_id), "Community does not exist");
        return (
            community[_id].id,
            community[_id].name,
            community[_id].description,
            community[_id].allowedCampaign,
            community[_id].campaignId,
            community[_id].raisedAmount,
            community[_id].feeAmount,
            community[_id].commisionAmount
        );
    }

    /**
     * @dev Allows a Community Manager to define which communities can create campaigns.
     * @param _id Array of addresses for allowed campaign creation.
     * @param _permission Array of addresses for allowed campaign creation.
     */
    function defineAllowedCampaigns(uint64 _id, bool _permission) external onlyCommunityManager {
        community[_id].allowedCampaign = _permission;
    }

    /**
     * @dev Checks if a community can create a campaign.
     * @param _id Address of the community.
     * @return True if the community can create a campaign, False otherwise.
     */
    function canCreateCampaign(uint64 _id) external view returns (bool) {
        return community[_id].allowedCampaign;
    }

    /**
     * @dev Allows a Community Manager to set approval for a specific expense address.
     * @param _expense Address of the expense.
     * @param _approved Boolean indicating approval status (True for approved, False otherwise).
     */
    function setExpenseApproval(address _expense, bool _approved) external onlyCommunityManager {
        // communities[msg.sender].approvedExpenses[_expense] = _approved;
    }

    /**
     * @dev Allows the Diamond contract (owner) to add an expense report for a specific year.
     * @param _year Year for the expense report.
     * @param _report Report data.
     */
    function addExpenseReport(uint256 _year, string memory _report) external onlyOwner {
        // ExpenseReport storage report = communities[msg.sender].expenseReports[_year];
        // report.reportData = new string[](1); // Create a new string array
        // report.reportData[0] = _report; // Assign _report to the first element
    }

    /**
     * @dev Allows retrieval of an expense report for a specific year.
     * @param _year Year for the expense report.
     * @return The report data for the given year.
     */
    function getExpenseReport(uint256 _year) external view returns (string[] memory) {
        // ExpenseReport storage report = communities[msg.sender].expenseReports[_year];
        // return report.reportData; // Access report data within the ExpenseReport struct
    }

    function addCampaign(uint64 _communityID, string memory _description, uint256 _targetAmount)
        public
        payable
        onlyCommunityOwner(_communityID)
        returns (Campaign)
    {
        // Campaign newCampaign = new Campaign{value: msg.value}(address(this), msg.sender, _description, _targetAmount);

        // if (community[id].allowedCampaign) {
        //     community[id].currentCampaign = newCampaign;
        //     community[id].allowedCampaign = false;
        // } else {
        //     // Campaign is already registered
        //     revert CampaignAlredyCreated();
        // }

        // return newCampaign;
    }

    /**
     * @dev Allows users to donate to a campaign.
     */
    function donate(uint64 _id) public payable {
        require(exists(_id), "Community does not exist");

        uint256 _amount = msg.value;
        // tx.gasprice * tx.gaslimit
        uint256 feeStorage = 100000;
        if (_amount <= feeStorage) {
            revert MinimunToPayNotAchieved();
        }
        uint256 commission = _amount * 1 / 1000;
        if (_amount >= 200000) {
            _amount = _amount - commission - feeStorage;
            // payable(communityManagerAddress).transfer(commission);
        } else {
            if (_amount >= 100101) {
                _amount = _amount - commission - feeStorage;
            } else {
                if (_amount > commission) {
                    _amount = 0;
                    feeStorage = _amount - commission;
                } else {
                    feeStorage = _amount;
                    commission = 0;
                    _amount = 0;
                }
            }
        }
        feeAmountAcc += feeStorage;
        commisionAmountAcc += commission;
        raisedAmountAcc += _amount;

        community[_id].feeAmount += feeStorage;
        community[_id].commisionAmount += commission;
        community[_id].raisedAmount += _amount;
    }

    /**
     * @dev Allows campaign owners to withdraw raised funds after the campaign is inactive.
     */
    function withdrawFunds(uint64 _communityID) external view onlyCommunityOwner(_communityID) {
        // require(active == false, "Campaign must be inactive to withdraw funds");
        revert CommuntyFundsCannotBeWithdraw();
    }

    /**
     * @dev Modifier to restrict function calls to Community Managers.
     */
    modifier onlyCommunityManager() {
        CommunityManager facet = CommunityManager(diamond);
        require(facet.isCommunityManager(msg.sender), "Only Community Manager can call this function");
        _;
    }

    /**
     * @dev Modifier to restrict function calls to Community Owner.
     */
    modifier onlyCommunityOwner(uint64 _communityID) {
        require(community[_communityID].communityOwners[msg.sender], "Only Community Owner can call this function");
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
        bytes4[] memory selectors = new bytes4[](3); // Adjust the number based on your functions

        // Function selector for getCommunity(address _communityAddress) (view)
        selectors[0] = Community.defineAllowedCampaigns.selector;

        // Function selector for getActiveCampaigns(address _communityAddress) (view) (optional)
        //selectors[1] = Community.getActiveCampaigns.selector;

        return selectors;
    }

    receive() external payable {
        revert CommuntyPaymmentMustUseDonateFunction();
    }

    fallback() external payable {
        revert CommuntyPaymmentMustUseDonateFunction();
    }
}
