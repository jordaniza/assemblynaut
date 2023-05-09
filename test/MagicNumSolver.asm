// begin contract creation code

69 602a601f5360206000f3 // PUSH10 (runtime bytecode) (see below)
60 00                   // PUSH MEMORY OFFSET (0 bytes) to return from
52                      // MSTORE (offset, value) the bytecode at position zero
60 0a                   // PUSH1 RETURN DATA SIZE (10 bytes - bytecode len)
60 16                   // PUSH1 MEMORY OFFSET (22 bytes - offset for padding)
f3                      // RETURN (offset, size)

// the returned bytecode from the contract create is the runtime bytecode:

60 2a                   // PUSH1 VALUE (0x2a = 42)
60 1f                   // PUSH1 MEMORY OFFSET (31 bytes)
53                      // MSTORE8 (offset, value)  
60 20                   // PUSH1 RETURN DATA SIZE (32 bytes)
60 00                   // PUSH1 MEMORY OFFSET
f3                      // RETURN (offset, size)

// returns a 32 byte value, with the least significant byte being 0x2a
