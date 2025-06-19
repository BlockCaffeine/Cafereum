// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cafereum is ERC721, Ownable {
    mapping(string => uint) public productPrices;

    mapping(address => uint) public coffeePurchases;
    mapping(address => uint) public espressoPurchases;
    
    // Top buyer reward NFTs (special token IDs)
    uint256 public constant TOP_COFFEE_BUYER_TOKEN_ID = 1111;
    uint256 public constant TOP_ESPRESSO_BUYER_TOKEN_ID = 2222;
    
    // Track current top buyers
    address public topCoffeeBuyer;
    address public topEspressoBuyer;
    
    // Flag to track internal transfers
    bool private _internalTransfer;

    event ProductPurchased(string productType, string productStrength);
    event TopCoffeeBuyerChanged(address previousBuyer, address newBuyer, uint purchaseCount);
    event TopEspressoBuyerChanged(address previousBuyer, address newBuyer, uint purchaseCount);

    constructor(
        uint singleCoffeePrice,
        uint doubleCoffeePrice,
        uint singleEspressoPrice,
        uint doubleEspressoPrice
    ) ERC721("Cafereum", "CAF") Ownable(msg.sender) {

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
        
        // Mint the reward NFTs to the contract at deployment
        _safeMint(address(this), TOP_COFFEE_BUYER_TOKEN_ID);
        _safeMint(address(this), TOP_ESPRESSO_BUYER_TOKEN_ID);
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

        // Update purchase counts
        if (compareStrings(productType, "SingleCoffee") || compareStrings(productType, "DoubleCoffee")) {
            coffeePurchases[msg.sender]++;
            // Check and update top coffee buyer automatically
            _checkAndUpdateTopCoffeeBuyer();
        } else if (compareStrings(productType, "SingleEspresso") || compareStrings(productType, "DoubleEspresso")) {
            espressoPurchases[msg.sender]++;
            // Check and update top espresso buyer automatically
            _checkAndUpdateTopEspressoBuyer();
        }

        emit ProductPurchased(productType, productStrength);
    }

    /*
     * Administrative functions
     * - setProductPrice: Set the price of a product
     * - getBalance: Get the contract balance
     * - withdraw: Withdraw the contract balance
     * - newOwner: Transfer ownership of the contract
     */

    function setProductPrice(string memory productType, uint price) public onlyOwner {
        require(isValidProductType(productType), "Invalid product type");
        require(isValidProductPrice(price), "Price must be greater than zero");
        productPrices[productType] = price;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function newOwner(address newAddress) public onlyOwner {
        transferOwnership(newAddress);
    }

    /*
     * Statistics functions
     * - getProductPurchaseCount: Get the number of purchases for a specific product
     * - getTotalPurchases: Get the total number of purchases for an address
     * - getCoffeePurchases: Get the number of coffee purchases for an address
     * - getEspressoPurchases: Get the number of espresso purchases for an address
     * - getTopBuyers: Get the current top buyers for coffee and espresso
     * - getTopBuyersWithCounts: Get the top buyers and their purchase counts
     */

    function getProductPurchaseCount(string memory product) public view returns (uint) {
        require(isValidProduct(product), "Invalid product");
        if (compareStrings(product, "Coffee")) {
            return coffeePurchases[msg.sender];
        } else {
            return espressoPurchases[msg.sender];
        }
    }

    // Public function to get total purchases for an address
    function getTotalPurchases(address buyer) public view returns (uint) {
        return coffeePurchases[buyer] + espressoPurchases[buyer];
    }

    // Public function to get coffee purchases for an address
    function getCoffeePurchases(address buyer) public view returns (uint) {
        return coffeePurchases[buyer];
    }

    // Public function to get espresso purchases for an address
    function getEspressoPurchases(address buyer) public view returns (uint) {
        return espressoPurchases[buyer];
    }

    // Function to check who currently holds the reward NFTs
    function getTopBuyers() public view returns (address coffee, address espresso) {
        return (topCoffeeBuyer, topEspressoBuyer);
    }

    // Function to get the top buyers and their purchase counts
    function getTopBuyersWithCounts() public view returns (
        address coffeeBuyer, 
        uint coffeePurchases_, 
        address espressoBuyer, 
        uint espressoPurchases_
    ) {
        return (
            topCoffeeBuyer, 
            topCoffeeBuyer != address(0) ? coffeePurchases[topCoffeeBuyer] : 0,
            topEspressoBuyer,
            topEspressoBuyer != address(0) ? espressoPurchases[topEspressoBuyer] : 0
        );
    }

    /*
     * NFT functions
     */

    // Override transfer functions to prevent external transfers of reward NFTs
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        
        // For reward NFTs, only allow minting or internal contract operations
        if (tokenId == TOP_COFFEE_BUYER_TOKEN_ID || tokenId == TOP_ESPRESSO_BUYER_TOKEN_ID) {
            // Allow minting (from == address(0)) or internal transfers
            if (from != address(0) && !_internalTransfer) {
                require(false, "Reward NFTs can only be transferred by contract");
            }
        }
        
        return super._update(to, tokenId, auth);
    }

    /*
     * Internal helper functions
     */

    // Internal function to check and update top coffee buyer
    function _checkAndUpdateTopCoffeeBuyer() internal {
        uint currentBuyerPurchases = coffeePurchases[msg.sender];
        uint topBuyerPurchases = topCoffeeBuyer != address(0) ? coffeePurchases[topCoffeeBuyer] : 0;

        // Special case: if the current buyer is already the top buyer, always emit event for their continued dominance
        if (msg.sender == topCoffeeBuyer && topCoffeeBuyer != address(0)) {
            emit TopCoffeeBuyerChanged(msg.sender, msg.sender, currentBuyerPurchases);
        }
        // Update if the current buyer has more purchases than the current top buyer
        // OR if they have equal purchases and are not already the top buyer (tie-breaker: most recent wins)
        else if (currentBuyerPurchases > topBuyerPurchases || 
            (currentBuyerPurchases == topBuyerPurchases && msg.sender != topCoffeeBuyer && topBuyerPurchases > 0)) {
            address previousTopBuyer = topCoffeeBuyer;
            
            _internalTransfer = true;
            
            // Transfer NFT from previous top buyer back to contract (if exists)
            if (previousTopBuyer != address(0)) {
                _transfer(previousTopBuyer, address(this), TOP_COFFEE_BUYER_TOKEN_ID);
            }
            
            // Transfer NFT to new top buyer
            _transfer(address(this), msg.sender, TOP_COFFEE_BUYER_TOKEN_ID);
            
            _internalTransfer = false;
            
            topCoffeeBuyer = msg.sender;
            
            emit TopCoffeeBuyerChanged(previousTopBuyer, msg.sender, currentBuyerPurchases);
        }
    }

    // Internal function to check and update top espresso buyer
    function _checkAndUpdateTopEspressoBuyer() internal {
        uint currentBuyerPurchases = espressoPurchases[msg.sender];
        uint topBuyerPurchases = topEspressoBuyer != address(0) ? espressoPurchases[topEspressoBuyer] : 0;

        // Special case: if the current buyer is already the top buyer, always emit event for their continued dominance
        if (msg.sender == topEspressoBuyer && topEspressoBuyer != address(0)) {
            emit TopEspressoBuyerChanged(msg.sender, msg.sender, currentBuyerPurchases);
        }
        // Update if the current buyer has more purchases than the current top buyer
        // OR if they have equal purchases and are not already the top buyer (tie-breaker: most recent wins)
        else if (currentBuyerPurchases > topBuyerPurchases || 
            (currentBuyerPurchases == topBuyerPurchases && msg.sender != topEspressoBuyer && topBuyerPurchases > 0)) {
            address previousTopBuyer = topEspressoBuyer;
            
            _internalTransfer = true;
            
            // Transfer NFT from previous top buyer back to contract (if exists)
            if (previousTopBuyer != address(0)) {
                _transfer(previousTopBuyer, address(this), TOP_ESPRESSO_BUYER_TOKEN_ID);
            }
            
            // Transfer NFT to new top buyer
            _transfer(address(this), msg.sender, TOP_ESPRESSO_BUYER_TOKEN_ID);
            
            _internalTransfer = false;
            
            topEspressoBuyer = msg.sender;
            
            emit TopEspressoBuyerChanged(previousTopBuyer, msg.sender, currentBuyerPurchases);
        }
    }

    function isValidProductType(string memory productType) internal pure returns (bool) {
        return (compareStrings(productType, "SingleCoffee") ||
            compareStrings(productType, "DoubleCoffee") ||
            compareStrings(productType, "SingleEspresso") ||
            compareStrings(productType, "DoubleEspresso"));
    }

    function isValidProduct(string memory product) internal pure returns (bool) {
        return (compareStrings(product, "Coffee") || compareStrings(product, "Espresso"));
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
