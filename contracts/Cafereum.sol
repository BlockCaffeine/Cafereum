// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Cafereum {
    address payable public owner;

    mapping(string => uint) public productPrices;

    event ProductPurchased(string productType, string productStrength);

    constructor(
        uint singleCoffeePrice,
        uint doubleCoffeePrice,
        uint singleEspressoPrice,
        uint doubleEspressoPrice
    ) {
        owner = payable(msg.sender);

        require(
            isValidProductPrice(singleCoffeePrice),
            "SingleCoffee price should be greater than zero"
        );
        require(
            isValidProductPrice(doubleCoffeePrice),
            "DoubleCoffee price should be greater than zero"
        );
        require(
            isValidProductPrice(singleEspressoPrice),
            "SingleEspresso price should be greater than zero"
        );
        require(
            isValidProductPrice(doubleEspressoPrice),
            "DoubleEspresso price should be greater than zero"
        );

        productPrices["SingleCoffee"] = singleCoffeePrice;
        productPrices["DoubleCoffee"] = doubleCoffeePrice;
        productPrices["SingleEspresso"] = singleEspressoPrice;
        productPrices["DoubleEspresso"] = doubleEspressoPrice;
    }
    /*
     * Product functions
     * - setProductPrice: Set the price of a product
     * - getProductPrice: Get the price of a product
     * - buyProduct: Buy a product
     */

    function getProductPrice(string memory productType) public view returns (uint) {
        return productPrices[productType];
    }

    function getProductNamesAndPrices() public view returns (string[] memory, uint[] memory) {
        string[] memory names = new string[](4);
        uint[] memory prices = new uint[](4);

        names[0] = "SingleCoffee";
        names[1] = "DoubleCoffee";
        names[2] = "SingleEspresso";
        names[3] = "DoubleEspresso";

        prices[0] = productPrices["SingleCoffee"];
        prices[1] = productPrices["DoubleCoffee"];
        prices[2] = productPrices["SingleEspresso"];
        prices[3] = productPrices["DoubleEspresso"];

        return (names, prices);
    }

    function buyProduct(string memory productType, string memory productStrength) public payable {
        require(isValidProductType(productType), "Invalid product type");
        require(isValidProductStrength(productStrength), "Invalid product strength");
        require(msg.value == productPrices[productType], "Incorrect amount sent");

        emit ProductPurchased(productType, productStrength);
    }

    /*
     * Administrative functions
     * - setProductPrice: Set the price of a product
     * - getBalance: Get the contract balance
     * - withdraw: Withdraw the contract balance
     */

    function setProductPrice(string memory productType, uint price) public {
        require(msg.sender == owner, "You are not the owner");
        require(isValidProductType(productType), "Invalid product type");
        require(isValidProductPrice(price), "Price must be greater than zero");
        productPrices[productType] = price;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the owner");

        uint amount = address(this).balance;
        owner.transfer(amount);
    }

    /*
     * Internal helper functions
     */

    function isValidProductType(string memory productType) internal pure returns (bool) {
        return (compareStrings(productType, "SingleCoffee") ||
            compareStrings(productType, "DoubleCoffee") ||
            compareStrings(productType, "SingleEspresso") ||
            compareStrings(productType, "DoubleEspresso"));
    }

    function isValidProductStrength(string memory productStrength) internal pure returns (bool) {
        return (compareStrings(productStrength, "Mild") ||
            compareStrings(productStrength, "Normal") ||
            compareStrings(productStrength, "Strong") ||
            compareStrings(productStrength, "Extra"));
    }

    function isValidProductPrice(uint price) internal pure returns (bool) {
        return price > 0;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }
}
