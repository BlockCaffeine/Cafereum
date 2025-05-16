// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Cafereum {
    uint public coffeePrice;
    address payable public owner;

    event ProductPurchased(string productType, string productStrength);

    constructor(uint _coffeePrice) {
        require(_coffeePrice > 0, "Coffee price should be greater than zero");

        coffeePrice = _coffeePrice;
        owner = payable(msg.sender);
    }

    function buyProduct(
        string memory productType,
        string memory productStrength
    ) public payable {
        require(msg.value == coffeePrice, "Incorrect amount sent");

        // Validate productType
        require(
            compareStrings(productType, "SingleCoffee") ||
                compareStrings(productType, "DoubleCoffee") ||
                compareStrings(productType, "SingleEspresso") ||
                compareStrings(productType, "DoubleEspresso"),
            "Invalid product type"
        );

        // Validate productStrength
        require(
            compareStrings(productStrength, "Mild") ||
                compareStrings(productStrength, "Normal") ||
                compareStrings(productStrength, "Strong") ||
                compareStrings(productStrength, "Extra"),
            "Invalid product strength"
        );

        emit ProductPurchased(productType, productStrength);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the owner");

        uint amount = address(this).balance;
        owner.transfer(amount);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }
}
