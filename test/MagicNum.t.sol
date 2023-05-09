pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MagicNum.sol";

contract ASMMagicNum is Test {
    MagicNum public target;
    // see MagicNumSolver for details
    bytes solverBytecode = hex"69602a601f5360206000f3600052600a6016f3";

    function setUp() public {
        target = new MagicNum();
    }

    function testAttackMagicNum() public {
        address _solver;

        assembly {
            // init fmp
            let ptr := mload(0x40)
            // we know there are less than 32 bytes so the data in the slot is the bytecode
            let data := sload(solverBytecode.slot)
            // save the data
            mstore(ptr, data)

            // length of the data is stored at the end of the slot in the last byte
            // we can fetch with a bitwise AND using a mask over the final byte
            let len := and(mload(ptr), 0xff)

            // we can pass the memory start offset and length to the create opcode
            // which will create a new sub context and return us the address where the init bytecode is deployed
            _solver := create(0, ptr, len)
        }

        target.setSolver(_solver);

        address solver = target.solver();

        assertLe(solver.code.length, 10);

        // the signature is irrelevant here
        (, bytes memory data) = solver.call(abi.encodeWithSignature("whatIsTheMeaningOfLife()"));

        uint256 decoded = abi.decode(data, (uint256));

        assertEq(decoded, 42);
    }
}
