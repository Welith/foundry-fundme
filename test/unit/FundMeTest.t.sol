// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract FundMeTest is Test {
    DeployFundMe deployFundMe;
    FundMe fundMe;

    address _user = makeAddr("user");

    uint256 constant _EXPECTED_AMOUNT = 1 ether;
    uint256 constant _USER_AMOUNT = 10 ether;
    uint256 constant _GAS_PRICE = 1 gwei;

    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(_user, _USER_AMOUNT);
    }

    function testGetDataFeedVersion() public view {
        uint256 version = fundMe.getDataFeedVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund{value: 0}();
    }

    function testFundUpdatesContributorsList() public funded {
        assertEq(fundMe.getAddressToAmountContributed(_user), _EXPECTED_AMOUNT);
    }

    function testFundUpdatesContributorsArray() public funded {
        address[] memory contributors = fundMe.getContributors();
        assertEq(contributors.length, 1);
        assertEq(contributors[0], _user);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(_user);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        uint256 contractBalance = fundMe.getContributionsAmount();
        uint256 ownerBalance = fundMe.getOwner().balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assertEq(fundMe.getContributionsAmount(), 0);
        assertEq(fundMe.getContributors().length, 0);
        assertEq(fundMe.getOwner().balance, ownerBalance + contractBalance);
        assertEq(fundMe.getAddressToAmountContributed(_user), 0);
    }

    function testWithdrawFromMultipleFunders() public {
        uint256 numberOfContributors = 10;
        uint256 startingContributorIndex = 1;

        // Create multiple contributors and add more funds to contract
        for (uint256 i = startingContributorIndex; i < numberOfContributors; ++i) {
            address user = makeAddr(string.concat("contributor ", Strings.toString(i)));
            hoax(user, _EXPECTED_AMOUNT);
            fundMe.fund{value: _EXPECTED_AMOUNT}();
        }

        uint256 contractBalance = fundMe.getContributionsAmount();
        uint256 ownerBalance = fundMe.getOwner().balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        assertEq(fundMe.getContributionsAmount(), 0);
        assertEq(fundMe.getOwner().balance, ownerBalance + contractBalance);
    }

    modifier funded() {
        vm.prank(_user);
        fundMe.fund{value: _EXPECTED_AMOUNT}();
        _;
    }
}
