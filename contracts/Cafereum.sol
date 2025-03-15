// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Cafereum {
    uint public coffeePrice;
    address payable public owner;

    event CoffeePurchased(address buyer, uint amount, uint when);

    constructor(uint _coffeePrice) {
        require(_coffeePrice > 0, "Coffee price should be greater than zero");

        coffeePrice = _coffeePrice;
        owner = payable(msg.sender);
    }

    function buyCoffee() public payable {
        require(msg.value == coffeePrice, "Incorrect amount sent");

        emit CoffeePurchased(msg.sender, msg.value, block.timestamp);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the owner");

        uint amount = address(this).balance;
        owner.transfer(amount);
    }
}
