// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "oz/utils/Address.sol";

/// aim is to drain the coin balance of the samaritan contract

contract GoodSamaritan {
    Wallet public wallet;
    Coin public coin;

    // contstructor uses the samaritan to link the coin and the wallet
    // the samaritan has a wallet that contains coins, the initial balance for the samaritan is 1mil
    constructor() {
        wallet = new Wallet();
        coin = new Coin(address(wallet));

        wallet.setCoin(coin);
    }

    /**
     * @dev this function trys to donate 10 coins from the samaritan
     *      if successful, returns true. Otherwise it enders the catch clause.
     *      where it transfers the remainder of the user's tokens IF the error is "NotEnoughBalance"
     *      Is it possible to mess with the error here?
     *      Technically, we could drain the wallet with 10000 requests.
     *      What we really want is to revert the donate10 so it transfers the remainder
     */
    function requestDonation() external returns (bool enoughBalance) {
        // donate 10 coins to requester
        try wallet.donate10(msg.sender) {
            return true;

            // IDEA: try/catch in solidity is janky
        } catch (bytes memory err) {
            if (
                keccak256(abi.encodeWithSignature("NotEnoughBalance()")) ==
                keccak256(err)
            ) {
                // send the coins left
                wallet.transferRemainder(msg.sender);
                return false;
            }
        }
    }
}

contract Coin {
    using Address for address;

    // balances is a pretty simple mapping here, there are no decimals
    mapping(address => uint256) public balances;

    error InsufficientBalance(uint256 current, uint256 required);

    constructor(address wallet_) {
        // one million coins for Good Samaritan initially
        balances[wallet_] = 10**6;
    }

    function transfer(address dest_, uint256 amount_) external {
        uint256 currentBalance = balances[msg.sender];

        // transfer only occurs if balance is enough
        if (amount_ <= currentBalance) {
            balances[msg.sender] -= amount_;
            balances[dest_] += amount_;

            if (dest_.isContract()) {
                // notify contract
                // this is interesting because
                // we can do anything here
                // so we could revert with the custom error if the
                // amount == 10
                INotifyable(dest_).notify(amount_);
            }
        } else {
            revert InsufficientBalance(currentBalance, amount_);
        }
    }
}

contract Wallet {
    // The owner of the wallet instance
    address public owner;

    Coin public coin;

    error OnlyOwner();
    error NotEnoughBalance();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev this function gets called by the Sam and passes msg.sender to the Wallet
     *      its ownable so must be called by the Sam.
     *      We need to check how balances are calculated here.
     */
    function donate10(address dest_) external onlyOwner {
        // check balance left
        if (coin.balances(address(this)) < 10) {
            revert NotEnoughBalance();
        } else {
            // donate 10 coins
            coin.transfer(dest_, 10);
        }
    }

    function transferRemainder(address dest_) external onlyOwner {
        // transfer balance left
        coin.transfer(dest_, coin.balances(address(this)));
    }

    function setCoin(Coin coin_) external onlyOwner {
        coin = coin_;
    }
}

interface INotifyable {
    function notify(uint256 amount) external;
}
