// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.18;

import "./BaseFacet.sol";
import "./Community.sol";
import "./CommunityManager.sol";

import "./Structs.sol";
import "forge-std/console.sol";

contract Campaign is BaseFacet {
    error CampaignPaymmentMustUseDonateFunction();
    error MinimunToPayNotAchieved();

    event Log(uint256 gas);

    // address public owner;
    // address payable public communityManagerAddress;
    // address payable public community;
    // string public description;
    // uint256 public targetAmount;
    // uint256 public raisedAmount;
    // uint256 public feeAmount;
    // uint256 public commisionAmount;
    // bool public active;

    uint256 public raisedAmountAcc;
    uint256 public feeAmountAcc;
    uint256 public commisionAmountAcc;

    mapping(uint64 => CampaignData) public campaing;

    /**
     * @dev Constructor that takes the name and description and initializes the Campaign.
     */
    constructor()  {
        creator = msg.sender;
    }

    function AddCampaing(
        uint64 _id,
        address _owner,
        uint64 _communityId,
        string memory _description,
        uint256 _targetAmount
    ) public {
        require(!existsCampaign(_id), "Campaign with this ID already exists");

        campaing[_id].owner = _owner;
        campaing[_id].communityId = _communityId;
        campaing[_id].description = _description;
        campaing[_id].targetAmount = _targetAmount;
        campaing[_id].raisedAmount = 0;
        campaing[_id].feeAmount = 0;
        campaing[_id].commisionAmount = 0;
        campaing[_id].active = true;
    }

    function RemoveCampaing(uint64 _id) public {
        require(existsCampaign(_id), "Campaign does not exist");
        delete campaing[_id];
    }

    function GetCampaing(uint64 _id)
        public
        view
        returns (uint64, address, string memory, uint256, uint256, uint256, uint256, bool)
    {
        require(existsCampaign(_id), "Campaign does not exist");
        return (
            campaing[_id].communityId,
            campaing[_id].owner,
            campaing[_id].description,
            campaing[_id].targetAmount,
            campaing[_id].raisedAmount,
            campaing[_id].feeAmount,
            campaing[_id].commisionAmount,
            campaing[_id].active
        );
    }

    function existsCampaign(uint64 _id) public view returns (bool) {
        return campaing[_id].owner != address(0); // Check owner field for validity
    }

    /**
     * @dev Allows users to donate to a campaign.
     */
    function donate(uint64 _id) public payable {
        require(existsCampaign(_id), "Campaign does not exist");
        require(campaing[_id].active, "Campaign is not active");

        uint256 _amount = msg.value;
        if (_amount <= 0) {
            revert MinimunToPayNotAchieved();
        }
        uint256 commission = _amount * 1 / 1000;
        // tx.gasprice * tx.gaslimit
        uint256 feeStorage = 100000;
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

        campaing[_id].feeAmount += feeStorage;
        campaing[_id].commisionAmount += commission;
        campaing[_id].raisedAmount += _amount;
    }

    /**
     * @dev Allows campaign owners to withdraw raised funds after the campaign is inactive.
     */
    function withdrawFunds(uint64 _campaignId) external onlyCampaignOwner {
        require(campaing[_campaignId].active == false, "Campaign must be inactive to withdraw funds");
        require(campaing[_campaignId].raisedAmount > 0 == false, "Campaign have no funds to transfer");
        payable(campaing[_campaignId].owner).transfer(campaing[_campaignId].raisedAmount);
        campaing[_campaignId].raisedAmount = 0;
    }

    /**
     * @dev This function allows a campaign owner to transfer funds from the campaign contract to the community funds address.
     *
     * Requirements:
     *
     * - The caller must be the owner of the campaign contract (enforced by the `onlyCampaignOwner` modifier).
     */
    function transferToCommunityFunds(uint64 _id) external onlyCampaignOwner {
        require(campaing[_id].active == false, "Campaign must be inactive to withdraw funds");
        require(campaing[_id].raisedAmount > 0 == false, "Campaign have no funds to transfer");
        Community(_id).donate{value: campaing[_id].raisedAmount}();
        campaing[_id].raisedAmount = 0;
    }

    /**
     * @dev This function allows a campaign owner to close  the campaign.
     *
     * Requirements:
     *
     * - The caller must be the owner of the campaign contract (enforced by the `onlyCampaignOwner` modifier).
     */
    function closeCampaign(uint64 _id) external onlyCampaignOwner {
        require(campaing[_id].active == false, "Campaign must be active to allow closure");

        campaing[_id].active == false = false;
    }

    /**
     * @dev This function allows the campaign owner to activate or deactivate a campaign.
     * It sets the `isActive` state of the campaign contract, indicating whether it's currently open for donations.
     *
     * Requirements:
     *
     * - The caller must be the owner of the campaign contract (enforced by `onlyCampaignOwner` modifier).
     */
    function setActive(uint64 _id) external onlyCampaignOwner {
        campaing[_id].active = true;
    }

    /**
     * @dev This function likely checks whether an address is the owner of a specific campaign.
     * It's probable that this function is used internally by other functions to control access based on ownership.
     *
     * Parameters:
     *
     * - `_owner` (address): The address to be verified as the campaign owner.
     * - `_campaign` (address): The address of the campaign contract to check ownership for.
     *
     * Returns:
     *
     * - (bool): Potentially returns `true` if `_owner` is the campaign owner for `_campaign`, and `false` otherwise. The actual return behavior depends on the implementation within the campaign contract.
     */
    function isCampaignOwner(address _owner, uint64 _id) public view returns (bool) {
        return _owner == campaing[_id].owner;
    }

    /**
     * @dev Modifier to restrict function calls to Campaign Owners for a specific campaign.
     */
    modifier onlyCampaignOwner(uint64 _id) {
        // Campaign facet = Campaign(diamond);
        require(this.isCampaignOwner(msg.sender), "Only Campaign Owner can call this function");
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
        bytes4[] memory selectors = new bytes4[](5); // Adjust the number based on your functions

        selectors[0] = Campaign.withdrawFunds.selector;

        selectors[1] = Campaign.transferToCommunityFunds.selector;

        selectors[2] = Campaign.setActive.selector;

        return selectors;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        revert CampaignPaymmentMustUseDonateFunction();

        // raisedAmount += msg.value;
        // donate(msg.value);
    }

    fallback() external payable {
        revert CampaignPaymmentMustUseDonateFunction();
    }
}
