# Multiverser Maketier ethglobal-bkk2024-mmm


## Introduction 

Multiverse Marketier (M^2) is a specialized bridge designed for cross-chain market makers. By deploying smart contracts across various blockchain networks and utilizing a centralized database, M^2 pools together liquidity to facilitate efficient cross-chain trading. This approach offers an alternative to intent-based swaps, providing significant benefits to larger liquidity providers by enhancing liquidity depth and trading opportunities.

This helps to bring in TradFi Market Makers into DeFi!

The platform is developing a user-friendly front-end interface where market makers can connect their wallets and access a coding environment to develop and implement their trading strategies. This feature empowers market makers to craft sophisticated, custom strategies that can operate seamlessly across multiple blockchain networks.

## Project Architecture

![Project Architecture](https://github.com/DarkArtistry/ethglobal-bkk2024-mmm/blob/8ac7a19666de0b58519311cf6c73231d48a5a63b/images/ethglobal-mmm.png)


## Project Architecture Overview

DEX Adapter: We have deployed a versatile DEX Adapter capable of integrating with any decentralized exchange (DEX) on any Ethereum Virtual Machine (EVM) compatible network. This adapter allows our system to seamlessly adjust and interact with various DEXs, providing flexibility and broad network compatibility.

Pool Contract: The Pool contract serves as a secure repository for holding funds. It manages the pooled liquidity from users, facilitating efficient fund management and trade execution.

Stash Contract: Users make their initial deposits through the Stash contract. It acts as the gateway for users to contribute assets to the system, ensuring that deposits are securely and accurately recorded.

Trade Contract: The Trade contract is where the centralized owner initiates trades. It interfaces with the Pool contract to execute swaps via the specified DEX Adapter. This setup allows for centralized control over trade operations while leveraging decentralized exchange mechanisms.

Sales Contract: To manage commissions, we have a Sales contract that receives fees generated from trades. It ensures that commission structures are enforced and that revenues are properly allocated.

Node.js Servers:

Event Listener Server: We have a Node.js server dedicated to listening for blockchain events, such as deposits and withdrawals. Upon detecting an event, it updates the user's balance in our centralized database, maintaining accurate and up-to-date account information.
API Server: Another Node.js server handles API calls from users. This server provides an interface for users to interact with the system, processing requests, executing commands, and retrieving necessary data.