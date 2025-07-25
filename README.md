# AI Model Rights NFT Registry

This smart contract allows the tokenization of AI model ownership and usage rights as non-fungible tokens (NFTs) on the Stacks blockchain using the Clarity language.

## Features

* **NFT Minting**: Tokenize an AI model by minting a new NFT with metadata including model name, hash, creator, license type, and usage fee.
* **Metadata Management**: Store and retrieve detailed metadata for each AI model NFT.
* **Marketplace Functions**: List AI model NFTs for sale, buy them, and unlist them.
* **Usage Licensing**: Purchase usage licenses for models, supporting limited-use or time-bound access with automatic fee distribution to the creator and token owner.
* **Access Control**: Only NFT owners can list or unlist tokens.

## Contract Components

### Data Structures

* **NFT**: `ai-model-rights` — token ID is a uint.
* **Metadata Map**: Maps token ID to model information.
* **Listings Map**: Maps token ID to price and listing status.
* **Usage Licenses Map**: Tracks licensing by token ID and licensee principal.

### Key Constants

* `platform-fee-percentage`: Set to 5% (u5).
* `contract-owner`: Initially set to the deployer (tx-sender).
* Error codes for ownership, listing, and payment validation.

### Public Functions

* `mint-model-nft`: Mint a new AI model NFT.
* `list-for-sale`: List an NFT for sale with a specified price.
* `unlist`: Remove an NFT from sale.
* `buy-model-nft`: Purchase a listed AI model NFT.
* `purchase-usage-license`: Pay for and acquire a limited-use license to an AI model.

### Read-Only Functions

* `get-token-metadata`
* `get-listing`
* `get-usage-license`
* `get-token-owner`

## Licensing Structure

Usage licenses are granted with:

* Block expiry limits.
* A max number of permitted uses.
* Fee sharing between the model creator (70%) and the current token owner (30%).

## Error Handling

Contract includes error handling for:

* Non-owners attempting restricted actions.
* Invalid or missing listings.
* Insufficient STX payment.
* Duplicate minting.
