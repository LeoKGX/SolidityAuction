# SolidityAuction
## Final exercise for module 2 of the ETHKipu course
The contract is for auctions where:
   - Each bid must exceed the best bid by at least 5%.
   - If there is a bid within the last 10 minutes, the time limit is extended by 10 minutes.
   - Participants may withdraw part of their deposit in excess of their last bid at any time before the end of the auction.
   - At the end, the winner is announced and the losers withdraw their bids minus a 2% commission to cover gas.

## STRUCTURES
### OfferInfo    
   This structure is the total deposit information and the last bid made by an address (mapping below).

- deposit   
   Total deposited by the bidder

- lastOffer   
   Amount of your last offer (to calculate what you can withdraw)

## VARIABLES
### owner         
   Who deploys the contract
### bestBidder    
   Address of the current best bidder
### bestOffer      
   Current highest bidder
### limitTime       
   Timestamp at which the auction ends (varies depending on when the contract is displayed)
### auctionClosed       
   Used to determine if the auction ended

      
## CONSTANTS 
### MIN_INCREASE
   Minimum percentage of change for a bid to be valid, in this case 5%.
### AUCTION_TIME
   Duration of the auction, in this case 12 minutes
### EXTENSION_TIME
   Time that the auction is extended within the last 10 minutes, in this case 10 minutes
### COMMISSION
   Percentage of commission that the contract will keep

## MAPPINGS AND ARRANGEMENTS
### bidders
   Mapping of address to your warehouse and last offer
### bidderList
   Mapping of all addresses that participated in the auction

## EVENTS
### NewOffer()
   Emitted each time a new valid bid is placed by a participant.
- bidder   
   Bidder's address Indexed for searches
- offer   
   Amount of the new bid
- newTime   
   New time limit
      
### AuctionEnded() 
   Emitted when the auction has ended
- winner    
   Winner's address
- winOffer    
   Amount of the winning bid

## MODIFIERS
### onlyOwner() 
   To check that the owner executes the action

### isActive() 
   Checks if the auction is still active

### isValidOffer() 
   Checks if the bid is valid


## BUILDER
  Designates owner who builds the contract and designates limitTime as the creation time plus the constant AUCTION_TIME.

## FUNCTIONS
### bid() 
   Checks that the auction is active and the bid is valid (with modifiers).
   It is to send a bid by sending ETH to the contract.


### partialRefund() Only while the auction is active (modifier isActive)
   This is to withdraw the deposit left in the contract after bidding several times.

### withdrawFinalized()
   Is for each person except the winner of the auction to withdraw the losing bids by deducting the COMMISSION.

### getWinner() 
   Returns the best bidder and the best offer in ETH.
    
### getOffers() 
   Return all bidders and all bids in ETH

### getTimeLeft()
   Returns, in seconds, the time left in the auction 
