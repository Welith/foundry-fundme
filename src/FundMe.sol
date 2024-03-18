// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address immutable i_owner;
    address[] private s_contributors;
    mapping(address => uint256) private s_contributions;
    AggregatorV3Interface internal s_priceFeed;

    uint256 public constant minUsd = 5;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getMinUsd(s_priceFeed) >= minUsd, "Fund value needs to be at least 5 USD!");
        s_contributors.push(msg.sender);
        s_contributions[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 contributorsLength = s_contributors.length;
        for (uint256 index = 0; index < contributorsLength; ++index) {
            s_contributions[s_contributors[index]] = 0;
        }

        s_contributors = new address[](0);

        (bool success,) = payable(i_owner).call{value: getContributionsAmount()}("");
        require(success);
    }

    function withdraw() public onlyOwner {
        for (uint256 index = 0; index < s_contributors.length; ++index) {
            s_contributions[s_contributors[index]] = 0;
        }
        s_contributors = new address[](0);

        (bool success,) = payable(i_owner).call{value: getContributionsAmount()}("");
        require(success);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        require(msg.sender == i_owner, "Function is only callable by owner of contract!");
        _;
    }

    function getDataFeedVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getContributors() public view returns (address[] memory) {
        return s_contributors;
    }

    function getContributor(uint256 contributorIndex) public view returns (address) {
        return s_contributors[contributorIndex];
    }

    function getContributionsAmount() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddressToAmountContributed(address contributor) public view returns (uint256) {
        return s_contributions[contributor];
    }
}
