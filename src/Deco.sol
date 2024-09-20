// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


// Purchase through moon token, moon store.
contract MyToken is ERC1155, Ownable {
    uint8 stock = 10;

    uint8 private _tokenId = 0;

    // track number of orders
    uint256 private _counterId;
    
    // link order number to buyers
    mapping(uint256 => address) buyerAddr;

    // shipping status
    mapping(uint256 => bool) isShipped;

    // buyer shipping address
    mapping(address => string) shippingAddr;

    // store multiple buyer id's
    mapping(address => uint8[]) buyerId;
    
    mapping(address => uint256) paid;

    uint256 public price;

    struct ShipDetails {
        bool isShipped;
        string trackingNo;
    }

    mapping(uint256 => ShipDetails) shipping;

    // string LINK = "https://bafybeiaium7ra2ho4zsdf6ix3t6waynpv2yuhmetd4ndeksd7xr5cqgezy.ipfs.nftstorage.link/";

    constructor() ERC1155(LINK) Ownable(msg.sender) {}

    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(
        abi.encodePacked(
            LINK,
            Strings.toString(tokenId),
            ".json"
        )
        );
    }
    
    function purchase(uint8 quantity, string memory destination) external payable {
        require(quantity < stock, "Invalid quanity");

        require(_counterId < stock - 1, "Out of stock");

        uint256 amount = msg.value;

        require((amount == price) && (amount > 0), "Amount not correct");

        // mint the token+

        _mint(msg.sender, _tokenId, 1, "");
        
        buyerAddr[_counterId] = msg.sender;

        // Buyer could have multiple orders.
        buyerId[msg.sender].push(_counterId);

        shippingAddr[msg.sender] = destination;

        paid[msg.sender] = price;

        _counterId++;
    }

    // Set tracking number from the email address.
    function updateShipment(uint256 tokenId, string memory trackingNo) external onlyOwner {
            ShipDetails storage sd = shipping[tokenId];

            require(!sd.isShipped, "Already Shipped");
            sd.isShipped = true;

            //  check the tracking number from the system.
            sd.trackingNo = trackingNo;
    }

    function setPrice(uint256 amount) external onlyOwner {
        price = amount;
    }
    function getIdOwner(uint256 nftId) external view returns(address) {
        return ownerAddr[nftId];
    }

    function totalSold() public view returns(uint256) {
        return _sold;
    }

    function getStatus() public view returns(
        ShipDetails memory sd = shipping[tokenId];
    )
}

// How to contact a buyer if there is a shipping problem?
