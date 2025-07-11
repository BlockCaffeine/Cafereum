// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cafereum is ERC721, Ownable {
    mapping(string => uint) public productPrices;

    mapping(address => uint) public espressoPurchases; // Dictionary to track espresso purchases per buyer
    address[] private espressoBuyers; // Array to track espresso buyers

    mapping(address => uint) public coffeePurchases; // Dictionary to track coffee purchases per buyer
    address[] private coffeeBuyers; // Array to track coffee buyers

    mapping(address => uint) public moneySpent; // Tracks the total Ether spent by each address

    // Overall counters for total purchases
    uint public totalCoffeePurchases; // Total coffee purchases across all users
    uint public totalEspressoPurchases; // Total espresso purchases across all users

    mapping(uint256 => string) private _tokenURIs; // NFT metadata storage

    // Top buyer reward NFTs (special token IDs)
    uint256 public constant TOP_COFFEE_BUYER_TOKEN_ID = 11;
    uint256 public constant TOP_ESPRESSO_BUYER_TOKEN_ID = 22;

    // Track current top buyers
    address public topCoffeeBuyer;
    address public topEspressoBuyer;

    // Milestone NFT system
    uint256 private _milestoneTokenCounter = 100; // Counter starting at 100 for milestone NFTs
    mapping(address => uint) private _lastPersonalMilestone; // Track last personal milestone for each buyer
    uint private _lastCafereumMilestoneMinted; // Track last Cafereum-wide milestone minted

    // Flag to track internal transfers
    bool private _internalTransfer;

    event ProductPurchased(string productType, string productStrength);
    event TopCoffeeBuyerChanged(address previousBuyer, address newBuyer, uint purchaseCount);
    event TopEspressoBuyerChanged(address previousBuyer, address newBuyer, uint purchaseCount);
    event MilestoneNFTMinted(address buyer, uint256 tokenId, string uri, uint256 milestone);

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
        setTokenURI(TOP_COFFEE_BUYER_TOKEN_ID, "ipfs://bafkreiciti6kni4b7ghsi5cy6d2txoo6lslwd2idgokh2jkcmyhs3dpy5u");

        _safeMint(address(this), TOP_ESPRESSO_BUYER_TOKEN_ID);
        setTokenURI(TOP_ESPRESSO_BUYER_TOKEN_ID, "ipfs://bafkreidwv5tskxeqydlr7glou2sgzhvzl55xwvfdhb2c6eh47geisd36h4");
    }

    /*
     * Product functions
     * - getProductPrice: Get the price of a product
     * - getProductNamesAndPrices: Get all product names and their prices
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

        moneySpent[msg.sender] += msg.value;

        if (
            compareStrings(productType, "SingleCoffee") ||
            compareStrings(productType, "DoubleCoffee")
        ) {
            recordCoffeePurchase(msg.sender, 1);
            _checkAndUpdateTopCoffeeBuyer();
        } else if (
            compareStrings(productType, "SingleEspresso") ||
            compareStrings(productType, "DoubleEspresso")
        ) {
            recordEspressoPurchase(msg.sender, 1);
            _checkAndUpdateTopEspressoBuyer();
        }

        // Check for milestone NFT minting after recording purchase
        bool freeProductPersonal = _checkAndMintPersonalMilestoneNFT(msg.sender);
        bool freeProductCafereum = _checkAndMintCafereumMilestoneNFT(msg.sender);

        
        // If milestone reached, refund the purchase amount
        if (freeProductPersonal || freeProductCafereum) {
            payable(msg.sender).transfer(msg.value);
            moneySpent[msg.sender] -= msg.value; // Adjust moneySpent since it's free
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
     * - recordCoffeePurchase: Record a coffee purchase
     * - getAllCoffeePurchases: Get all coffee purchases with their respective counts
     * - recordEspressoPurchase: Record an espresso purchase
     * - getAllEspressoPurchases: Get all espresso purchases with their respective counts
     * - mapCoffeeToObjects: Map coffee/espresso purchases to degree and object name
     * - getMostFrequentlyOrderedCategory: Get the most frequently ordered category and its count of specific buyer
     * - getProductPurchaseCount: Get the number of purchases for a specific product across all users
     * - getTotalPurchasesCountOverall: Get the total number of purchases across all users and products
     * - getTotalPurchasesCount: Get the total number of purchases for an address
     * - getCoffeePurchases: Get the number of coffee purchases for an address
     * - getEspressoPurchases: Get the number of espresso purchases for an address
     * - getMoneySpent: Get the total money spent by an address
     * - getTopBuyers: Get the current top buyers for coffee and espresso
     * - getTopBuyersWithCounts: Get the top buyers and their purchase counts
     */

    // Function to record coffee purchases
    function recordCoffeePurchase(address buyer, uint count) internal {
        if (coffeePurchases[buyer] == 0) {
            coffeeBuyers.push(buyer); // Add buyer to the list if not already present
        }
        coffeePurchases[buyer] += count;
        totalCoffeePurchases += count; // Update global counter
    }

    // Function to get all coffee purchases with their respective counts
    function getAllCoffeePurchases()
        public
        view
        returns (address[] memory buyers, uint[] memory counts)
    {
        uint length = coffeeBuyers.length;
        buyers = new address[](length);
        counts = new uint[](length);

        for (uint i = 0; i < length; i++) {
            buyers[i] = coffeeBuyers[i];
            counts[i] = coffeePurchases[coffeeBuyers[i]];
        }

        return (buyers, counts);
    }

    // Function to record espresso purchases
    function recordEspressoPurchase(address buyer, uint count) internal {
        if (espressoPurchases[buyer] == 0) {
            espressoBuyers.push(buyer); // Add buyer to the list if not already present
        }
        espressoPurchases[buyer] += count;
        totalEspressoPurchases += count; // Update global counter
    }

    // Function to get all espresso purchases with their respective counts
    function getAllEspressoPurchases()
        public
        view
        returns (address[] memory buyers, uint[] memory counts)
    {
        uint length = espressoBuyers.length;
        buyers = new address[](length);
        counts = new uint[](length);

        for (uint i = 0; i < length; i++) {
            buyers[i] = espressoBuyers[i];
            counts[i] = espressoPurchases[espressoBuyers[i]];
        }

        return (buyers, counts);
    }

    // Function to map coffee purchases to the degree (number of objects) and object name
    function mapCoffeeToObjects(
        address buyer
    ) public view returns (uint degree, string memory object) {
        uint coffeeCount = coffeePurchases[buyer]; // Get the number of coffees purchased by the buyer
        uint espressoCount = espressoPurchases[buyer]; // Get the number of espressos purchased by the buyer
        uint totalMilliliters = (coffeeCount + espressoCount) * 200; // Convert total drinks to milliliters (1 drink = 200 ml)

        // Map milliliters to objects
        if (totalMilliliters < 2000) {
            // Less than 2 liters: Baby Bottles (1 Baby Bottle = 250 ml)
            degree = totalMilliliters / 250;
            object = "Baby Bottle";
        } else if (totalMilliliters < 10000) {
            // Between 2 liters and 10 liters: Buckets (1 Bucket = 750 ml)
            degree = totalMilliliters / 750;
            object = "Bucket";
        } else if (totalMilliliters < 50000) {
            // Between 10 liters and 50 liters: Bathtubs (1 Bathtub = 50 liters = 50,000 ml)
            degree = totalMilliliters / 50000;
            object = "Bathtub";
        } else {
            // 50 liters or more: Swimming Pools (1 Swimming Pool = 2,500,000 liters = 2,500,000,000 ml)
            degree = totalMilliliters / 2500000000;
            object = "Swimming Pool";
        }

        return (degree, object);
    }

    function getMostFrequentlyOrderedCategory(
        address buyer
    ) public view returns (string memory mostOrderedCategory, uint orderCount) {
        // Get the total coffee purchases for the buyer
        uint buyerCoffeePurchases = coffeePurchases[buyer];

        // Get the total espresso purchases for the buyer
        uint buyerEspressoPurchases = espressoPurchases[buyer];

        // Compare coffee and espresso purchases for the buyer
        if (buyerCoffeePurchases >= buyerEspressoPurchases) {
            mostOrderedCategory = "Coffee";
            orderCount = buyerCoffeePurchases;
        } else {
            mostOrderedCategory = "Espresso";
            orderCount = buyerEspressoPurchases;
        }

        return (mostOrderedCategory, orderCount);
    }

    function getProductPurchaseCount(string memory product) public view returns (uint) {
        require(isValidProduct(product), "Invalid product");
        
        if (compareStrings(product, "Coffee")) {
            return totalCoffeePurchases;
        } else {
            return totalEspressoPurchases;
        }
    }

    function getTotalPurchasesCountOverall() public view returns (uint) {
        return totalCoffeePurchases + totalEspressoPurchases;
    }

    // Public function to get total purchases for an address
    function getTotalPurchasesCount(address buyer) public view returns (uint) {
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

    // Public function to get the total money spent by an address
    function getMoneySpent(address buyer) public view returns (uint) {
        return moneySpent[buyer];
    }

    // Function to check who currently holds the reward NFTs
    function getTopBuyers() public view returns (address coffee, address espresso) {
        return (topCoffeeBuyer, topEspressoBuyer);
    }

    // Function to get the top buyers and their purchase counts
    function getTopBuyersWithCounts()
        public
        view
        returns (
            address coffeeBuyer,
            uint coffeePurchases_,
            address espressoBuyer,
            uint espressoPurchases_
        )
    {
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

    // Function to set token URI for reward NFTs (only owner)
    function setTokenURI(uint256 tokenId, string memory uri) private {
        _tokenURIs[tokenId] = uri;
    }

    // Override tokenURI to return custom metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "ERC721: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    // Override transfer functions to prevent external transfers of reward NFTs
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
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

    // Function to mint milestone NFTs
    function _mintMilestoneNFT(
        address buyer,
        string memory uri,
        uint256 milestone
    ) internal {
        require(buyer != address(0), "Invalid buyer address");
        require(milestone > 0, "Milestone must be greater than zero");

        // Mint the milestone NFT
        _safeMint(buyer, _milestoneTokenCounter);
        setTokenURI(_milestoneTokenCounter, uri);

        emit MilestoneNFTMinted(buyer, _milestoneTokenCounter, uri, milestone);

        _milestoneTokenCounter++; 
    }

    /*
     * Internal helper functions
     * - _checkAndUpdateTopCoffeeBuyer: Check and update the top coffee buyer
     * - _checkAndUpdateTopEspressoBuyer: Check and update the top espresso buyer
     * - _checkAndMintPersonalMilestoneNFT: Check and mint milestone NFTs
     * - _checkAndMintCafereumMilestoneNFT: Check and mint Cafereum milestone NFTs
     * - isValidProductType: Check if a product type is valid
     * - isValidProduct: Check if a product is valid
     * - isValidProductStrength: Check if a product strength is valid
     * - isValidProductPrice: Check if a product price is valid
     * - compareStrings: Compare two strings for equality
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
        else if (
            currentBuyerPurchases > topBuyerPurchases ||
            (currentBuyerPurchases == topBuyerPurchases &&
                msg.sender != topCoffeeBuyer &&
                topBuyerPurchases > 0)
        ) {
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
        uint topBuyerPurchases = topEspressoBuyer != address(0)
            ? espressoPurchases[topEspressoBuyer]
            : 0;

        // Special case: if the current buyer is already the top buyer, always emit event for their continued dominance
        if (msg.sender == topEspressoBuyer && topEspressoBuyer != address(0)) {
            emit TopEspressoBuyerChanged(msg.sender, msg.sender, currentBuyerPurchases);
        }
        // Update if the current buyer has more purchases than the current top buyer
        // OR if they have equal purchases and are not already the top buyer (tie-breaker: most recent wins)
        else if (
            currentBuyerPurchases > topBuyerPurchases ||
            (currentBuyerPurchases == topBuyerPurchases &&
                msg.sender != topEspressoBuyer &&
                topBuyerPurchases > 0)
        ) {
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

    function _checkAndMintPersonalMilestoneNFT(address buyer) internal returns (bool) {
        uint totalPurchases = getTotalPurchasesCount(buyer);
        uint lastPersonalMilestone = _lastPersonalMilestone[buyer];

        string memory personalMilestoneURI = "ipfs://bafkreiha2renmdc77vrdpi5qp3cl3rgyq7jyytq577oj2lhh3xpvlnjq5m";

        // Check if the buyer has reached a new milestone
        if (totalPurchases == 1 && lastPersonalMilestone < 1) {
            _mintMilestoneNFT(buyer, personalMilestoneURI, 1);
            _lastPersonalMilestone[buyer] = 1;
        } else if (totalPurchases == 5 && lastPersonalMilestone < 5) {
            _mintMilestoneNFT(buyer, personalMilestoneURI, 5);
            _lastPersonalMilestone[buyer] = 5;
        } else if (totalPurchases == 10 && lastPersonalMilestone < 10) {
            _mintMilestoneNFT(buyer, personalMilestoneURI, 10);
            _lastPersonalMilestone[buyer] = 10;
        } else if (totalPurchases % 20 == 0 && totalPurchases > 0 && totalPurchases > lastPersonalMilestone) {
            // Mint a milestone NFT for every 20th purchase
            _mintMilestoneNFT(buyer, personalMilestoneURI, totalPurchases);
            _lastPersonalMilestone[buyer] = totalPurchases;
            return true; // Return true to indicate a free product
        }
        return false; // Return false to indicate no free product
    }

    function _checkAndMintCafereumMilestoneNFT(address buyer) internal returns (bool) {
        uint totalPurchasesCount = getTotalPurchasesCountOverall();

        // Check for Cafereum-wide milestones (e.g., every 100 total purchases)
        if (totalPurchasesCount % 100 == 0 && totalPurchasesCount > 0 && totalPurchasesCount > _lastCafereumMilestoneMinted) {
            string memory cafereumMilestoneURI = "ipfs://bafkreib2hrng73y574zucgkfqio7csy7kz27aqphnwthjir3c6etrcfwvi";
            _mintMilestoneNFT(buyer, cafereumMilestoneURI, totalPurchasesCount);
            _lastCafereumMilestoneMinted = totalPurchasesCount;
            return true; // Return true to indicate a free product
        }
        return false; // Return false to indicate no free product
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
