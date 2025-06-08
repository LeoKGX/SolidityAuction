// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//The contract is for auctions where:
//   - Each bid must exceed the best bid by at least 5%.
//   - If there is a bid within the last 10 minutes, the time limit is extended by 10 minutes.
//   - Participants may withdraw part of their deposit in excess of their last bid at any time before the end of the auction.
//   - At the end, the winner is announced and the losers withdraw their bids minus a 2% commission to cover gas.
contract Auction {

// STRUCTURES
// OfferInfo
// This structure is the total deposit information and the last bid made by an address (mapping below).
    struct OfferInfo {
        uint256 deposit;          // Total deposited by the bidder
        uint256 lastOffer;        // Amount of your last offer (to calculate what you can withdraw)
    }

// VARIABLES
    address private owner;         // Who deploys the contract
    address private bestBidder;    // Address of the current best bidder
    uint256 private bestOffer;     // Current highest bidder
    uint256 private limitTime;     // Timestamp at which the auction ends (varies depending on when the contract is deployed)
    bool    private auctionClosed; // Used to determine if the auction ended

//  CONSTANTES 
    uint256 private constant MIN_INCREASE = 5;             // Minimum percentage of change for a bid to be valid, in this case 5%.
    uint256 private constant AUCTION_TIME = 12 minutes;    // Duration of the auction, in this case 12 minutes
    uint256 private constant EXTENSION_TIME = 10 minutes;  // Time that the auction is extended within the last 10 minutes, in this case 10 minutes
    uint256 private constant COMMISSION = 2;               // Percentage of commission that the contract will keep

//MAPEOS Y ARREGLOS
    mapping(address => OfferInfo) private bidders;        // Mapping of address to their balance and last offer
    address[] private bidderList;                         // Array of all addresses that participated in the auction


// EVENTS

    // NewOffer()  Emitted each time a new valid bid is placed by a participant
    // bidder      Bidder's address Indexed for searches
    // offer       Amount of the new bid
    // newTime     New time limit
    event NewOffer(address indexed bidder, uint256 offer, uint256 newTime);

    // AuctionEnded() Emitted when the auction has ended
    // winner         Winner's address
    // winOffer       Amount of the winning offer
    event AuctionEnded(address indexed winner, uint256 winOffer);


//MODIFIERS

    // onlyOwner() To check that the owner executes the action
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    // isActive() Checks if the auction is still active
    modifier isActive() {
        require(block.timestamp < limitTime, "Auction Closed");
        _;
    }

    // isValidOffer() Checks if the bid is valid
    modifier isValidOffer() {
        require(msg.value > 0, "Must send ETH");
        if (bestOffer == 0) {
            require(msg.value >= 1 ether, "Send < 1ETH");
        } else {
            require(msg.value >= (bestOffer * MIN_INCREASE) / 100, "Send < Best Offer");
        }
        _;
    }

//CONSTRUCTOR
    // Designates owner who builds the contract and
    // designates limitTime as the creation time plus the constant AUCTION_TIME
    constructor() {
        owner = msg.sender;
        limitTime = block.timestamp + AUCTION_TIME;
    }


//FUNCTIONS

    // bid() Checks that the auction is active and the bid is valid (with modifiers)
    // It is to send a bid by sending ETH to the contract
    function bid() external payable isActive isValidOffer {

        OfferInfo storage info = bidders[msg.sender];

        // Check if the address sending the offer is in the list of bidders
        if (info.deposit == 0) {
            bidderList.push(msg.sender);
        }

        // Add the value of the offer to the previous deposits
        info.deposit += msg.value;
        // Updates the last offer
        info.lastOffer = msg.value;

        // Updates the best bidder and the best offer
        bestOffer = msg.value;
        bestBidder = msg.sender;

        // If the offer was made in the last 10 minutes add EXTENSION_TIME which in this case is 10 minutes as well
        if (limitTime - block.timestamp <= 10 minutes) {
            limitTime = block.timestamp + EXTENSION_TIME;
        }

        // Emits the event NewOffer()
        emit NewOffer(msg.sender, bestOffer, limitTime);
    }

    // partialRefund() Only while the auction is active (modifier isActive)
    // This is to withdraw the deposit left in the contract after bidding several times varias veces
    function partialRefund() external isActive {
        OfferInfo storage info = bidders[msg.sender];
        // Calculates the participant's surplus
        uint256 excedente = info.deposit - info.lastOffer;

        // If the surplus is less than or equal to 0, reverses
        require(excedente > 0, "No excess");
        // Updates deposits leaving only the last deposited offer
        info.deposit = info.lastOffer;
        // Sends the ETH
        (bool ok, ) = msg.sender.call{value: excedente}("");
        require(ok, "Transfer failed");
    }

    // withdrawFinalized()
    // Is for each person except the winner of the auction to withdraw the losing bids by deducting the COMMISSION
    function withdrawFinalized() external  {
        // Checks if the auction ended
        require(block.timestamp > limitTime, "Auction still active");
        // Checks that you're not the winner
        require(msg.sender != bestBidder, "Winner can't withdraw");

        OfferInfo storage info = bidders[msg.sender];
        require(info.deposit > 0 , "Nothing to withdraw");
        // If you have deposited ETH calculate the payment discounting COMMISSION
        uint256 pay = (info.deposit * (100 - COMMISSION)) / 100;
        // Update balance and send the payment
        bidders[msg.sender].deposit = 0;
        (bool ok, ) = msg.sender.call{value: pay}("");
        require(ok, "Transfer Failed");

        // Emits the AuctionEnded() event one time
        if (!auctionClosed) {
            emit AuctionEnded(bestBidder, bestOffer);
            auctionClosed == true;
        }
        
    }

    // getWinner() Returns the best bidder and the best offer in ETH
    function getWinner() external view returns (address, uint256) {
        return (bestBidder, (bestOffer/ 1000000000000000000));
    }

    // getOffers() Return all bidders and all bids in ETH
    function getOffers() external view returns (address[] memory addresses, uint256[] memory amounts) {
        uint256 count = bidderList.length;
        addresses = new address[](count);
        amounts = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            address addr = bidderList[i];
            addresses[i] = addr;
            amounts[i] = (bidders[addr].lastOffer / 1000000000000000000 );
        }
    }

    // getTimeLeft() Returns, in seconds, the time left in the auction 
    function getTimeLeft() external view returns (uint256) {
        return (block.timestamp >= limitTime) ? 0 : limitTime - block.timestamp;
    }


}
