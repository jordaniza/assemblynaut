# Assemblynaut

Today's young kids have no respect for the traditions of old. Back in my day, we had to write our own assembly code. We had to write our own assembly code in the dark. We had to write our own assembly code in the dark and with a stick. We had to write our own assembly code in the dark and with a stick while being chased by a bear. We had to write our own assembly code in the dark and with a stick while being chased by a bear and it was uphill both ways.

Inspired by masochism and a deep desire to learn how to count in hexadecimal, this repo is my attempt to solve the popular OpenZepplin [Ethernaut](https://ethernaut.openzeppelin.com/) challenges using only assembly.

## Solved Challenges

See the [test folder](./test) for solutions. I've actually never done the Ethernaut challenges "for real", so I am making the bold assumption they will be doable for me in Solidity.

### Challenges

- [x] Fallback: grabbing function selectors and lining up external calls. Was a great introduction.
- [ ] Fal1out: I know how to solve this, but the solution is "easier" than fallback so I might do a pure bytecode attempt later
- [x] CoinFlip: very easy, even with assembly due to inbuilt opcodes.
  - [ ] TODO: call vm.roll inside assembly
- [x] Telephone: actually was quite tough as required creating a new contract from compiled bytecode, very educational
- [x] Token: straightforward given previous challenges
- [x] Delegation: in assembly this is particularly easy to implement
- [x] Force: required loading constructor arguments to bytecode
- [x] Vault: pure asm implmentation including call to the forge cheatcodes
- [ ] King
- [ ] Reentrancy
- [ ] Elevator
- [x] Preservation: reuses most of the same concepts so was fairly straightforward. Neat little assembly optimisation for the attack contract

## Running the repo

Make sure you have foundry installed, run foundryup to get the latest version, and then run `forge install` to install the dependencies.

To run the tests, run `forge test` from the root of the repo.

## Suggestions and Improvements

If reading some of these solutions makes you weep with shame, please feel free to open an issue or submit a PR. I'll also be trying to post accompanying articles to explain each solution in more depth but, no promises.
