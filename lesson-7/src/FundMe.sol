// Refer to https://docs.soliditylang.org/en/v0.8.16/style-guide.html for style guide and
// https://github.com/smartcontractkit/chainlink/blob/281eedc27b1fff2df5dc3ec680a3aebaf3fd48f1/contracts/STYLE.md

// XX.sol
// |- license
// |- pragma
// |- imports
// |- contract (1 interface or 1 library or 1 contract per file)
// |- - errors
// |- - Type declarations
// |- - State variables
// |- - Events
// |- - Modifiers
// |- - Functions
// | - - - constructor
// | - - - receive function
// | - - - fallback function
// | - - - external
// | - - - public
// | - - - internal
// | - - - private
// | - - - view & pure functions

// License
// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.19;

// Imports
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// Interfaces, Libraries, Contracts
// Refer to https://docs.soliditylang.org/en/v0.5.7/layout-of-source-files.html#comments and
// https://jeancvllr.medium.com/solidity-tutorial-all-about-comments-bc31c729975a for comments guide
/**
 * @title TITLE
 * @author AUTHOR
 * @notice EXPLANATION
 * @dev EXTRA DETAILS
 */
contract FundMe {
    // Errors
    error FundMe__NotOwner();

    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;

    address private immutable i_owner;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);

        i_owner = msg.sender;
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );

        s_addressToAmountFunded[msg.sender] += msg.value;

        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];

            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");

        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];

            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");

        require(success);
    }

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
