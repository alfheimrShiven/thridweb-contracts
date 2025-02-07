// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { EntryPoint } from "contracts/prebuilts/account/utils/EntryPoint.sol";
import { GuardianAccountFactory } from "contracts/prebuilts/account/guardian/GuardianAccountFactory.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { IAccountGuardian } from "contracts/prebuilts/account/interface/IAccountGuardian.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract AccountGuardianTest is Test {
    address smartAccount;
    GuardianAccountFactory guardianAccountFactory;
    AccountGuardian accountGuardian;
    Guardian public guardianContract;
    AccountLock public accountLock;
    address randomUser = makeAddr("randomUser");
    address guardian = makeAddr("guardian");

    event GuardianRemoved(address indexed guardian);

    function setUp() public {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (smartAccount, guardianAccountFactory, guardianContract, accountLock, , ) = deployer.run();

        // retrieving the deployed accountGuardian contract address from the guardianContracts as it maintains a mapping of smartAccount => accountGuardian contracts.
        accountGuardian = AccountGuardian(guardianContract.getAccountGuardian(smartAccount));
    }

    modifier addVerifiedGuardian() {
        vm.prank(guardian);
        guardianContract.addVerifiedGuardian();
        _;
    }

    //////////////////////////
    /// addGuardian() tests///
    //////////////////////////
    function testRevertIfGuardianAddedNotByOwner() public {
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(AccountGuardian.NotAuthorized.selector, randomUser));
        accountGuardian.addGuardian(randomUser);
    }

    function testRevertOnAddingUnverifiedGuardian() public {
        vm.prank(smartAccount);
        vm.expectRevert(abi.encodeWithSelector(IAccountGuardian.GuardianCouldNotBeAdded.selector, randomUser));

        accountGuardian.addGuardian(randomUser);
    }

    function testAddGuardianAddsGuardianToList() public addVerifiedGuardian {
        // ACT
        vm.startPrank(smartAccount);
        accountGuardian.addGuardian(guardian);

        address[] memory accountGuardians = accountGuardian.getAllGuardians();
        vm.stopPrank();

        assertEq(accountGuardians.length, 1);
        assertEq(accountGuardians[0], guardian);
    }

    /////////////////////////////
    /// removeGuardian() tests///
    /////////////////////////////

    function testRevertRemoveGuardianNotByOwner() external {
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(AccountGuardian.NotAuthorized.selector, randomUser));
        accountGuardian.removeGuardian(guardian);
    }

    function testRevertIfRemovingGuardianThatDoesNotExist() external {
        vm.prank(smartAccount);
        vm.expectRevert(abi.encodeWithSelector(IAccountGuardian.NotAGuardian.selector, guardian));
        accountGuardian.removeGuardian(guardian);
    }

    function testRemoveGuardianRemovesGuardianFromList() external addVerifiedGuardian {
        // SETUP
        vm.startPrank(smartAccount);
        accountGuardian.addGuardian(guardian);

        // Act
        vm.expectEmit(true, false, false, false, address(accountGuardian));
        emit GuardianRemoved(guardian);
        accountGuardian.removeGuardian(guardian);

        // ASSERT
        address[] memory accountGuardians = accountGuardian.getAllGuardians();
        vm.stopPrank();
        assertEq(accountGuardians.length, 0);
    }

    /////////////////////////////
    /// getAllGuardians() tests///
    /////////////////////////////

    function testRevertIfNotOwnerTriesToGetGuardians() external {
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(AccountGuardian.NotAuthorized.selector, randomUser));
        accountGuardian.getAllGuardians();
    }

    function testGetAllGuardians() external addVerifiedGuardian {
        // SETUP
        vm.startPrank(smartAccount);
        accountGuardian.addGuardian(guardian);

        // ACT
        address[] memory accountGuardians = accountGuardian.getAllGuardians();
        vm.stopPrank();

        // Assert
        assertEq(accountGuardians[0], guardian);
    }

    ////////////////////////////////
    /// isAccountGuardain() tests///
    ////////////////////////////////

    function testIsAccountGuardian() external addVerifiedGuardian {
        //SETUP
        vm.startPrank(smartAccount);
        accountGuardian.addGuardian(guardian);

        // Assert
        bool isAccountGuardian = accountGuardian.isAccountGuardian(guardian);
        vm.stopPrank();

        assertEq(isAccountGuardian, true);
    }
}
