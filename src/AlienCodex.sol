pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function make_contact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    /**
     * @dev solidity 5 behaviour for replicating `codex.length--`;
     *      remove the item from the array and decrease the length by one
     *      do not check for underflow and allow writing to existing storage slots
     *      This allows us to rebuild the exploit with the same compiler and also
     *      is another excuse to use assembly
     *      I have no idea if this is what was intended but it's been a good exercise nonetheless
     *
     */
    function retract() public contacted {
        assembly {
            let ptr := mload(0x40)

            // fetch the length of the array
            let len := sload(codex.slot)

            // values start at hash of slot
            mstore(ptr, codex.slot)
            let startAddress := keccak256(ptr, 0x20)

            // decrement length by one
            sstore(codex.slot, sub(len, 0x01))

            // get the last item in the array (0 indexed)
            let lastAddress := add(startAddress, sub(len, 0x01))
            // set to zero
            sstore(lastAddress, 0x00)
        }
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
