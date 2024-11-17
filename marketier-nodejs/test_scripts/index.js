require('dotenv').config();
const { ethers } = require('ethers');
// server/index.js
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

// Connect to Anvil
const provider = new ethers.JsonRpcProvider(process.env.ETHEREUM_RPC_URL);

// Create a signer using Anvil's account
const privateKey = process.env.PRIVATE_KEY;
const signer = new ethers.Wallet(privateKey, provider);

// Replace with your contract's ABI and address
// Load ABIs
const TradeABI = JSON.parse(fs.readFileSync(path.join(__dirname, '../abis/Trade.json')));
const StashABI = JSON.parse(fs.readFileSync(path.join(__dirname, '../abis/Stash.json')));
const stashAddress = process.env.STASH_CONTRACT_ADDRESS; // Replace with the deployed Stash contract address

const stashContract = new ethers.Contract(stashAddress, StashABI, signer);

async function verifyChain() {
    const network = await provider.getNetwork();
    const chainId = Number(network.chainId);
    console.log('Connected to chain ID:', chainId);
    
    // // Since we're forking mainnet, chainId should be 1
    // if (chainId !== 1) {
    //     throw new Error(`Wrong chain ID. Expected 1 (mainnet), got ${chainId}`);
    // }
    return chainId;
}

// Function to trigger depositToken
async function triggerDeposit() {
    // Verify chain first
    const chainId = await verifyChain();
    // Token and amount
    const linkTokenAddress = '0x514910771AF9Ca656af840dff83E8264EcF986CA';
    const usdcTokenAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
    const linkAmount = ethers.parseUnits('1', 18); // 1 LINK
  
    // ABIs
    const linkAbi = [
      "function approve(address spender, uint256 amount) public returns (bool)",
      "function balanceOf(address account) public view returns (uint256)"
    ];
  
    // Contracts
    const linkContract = new ethers.Contract(linkTokenAddress, linkAbi, signer);
    const usdcContract = new ethers.Contract(usdcTokenAddress, linkAbi, signer);
    const stashContract = new ethers.Contract(stashAddress, StashABI, signer);
  
    try {  
      // Check LINK balance
      const balance = await linkContract.balanceOf(signer.address);
      console.log('LINK Balance:', ethers.formatUnits(balance, 18));
  
      // Approve
      console.log('Approving LINK...');
      const approveTx = await linkContract.approve(stashAddress, linkAmount);
      await approveTx.wait();
      console.log('Approved LINK tokens for Stash contract');

      const addToken = await stashContract.addSupportedToken(linkTokenAddress);
      await addToken.wait();

      const addUsdcToken = await stashContract.addSupportedToken(usdcContract);
      await addUsdcToken.wait();

      // Deposit
      console.log('Depositing LINK...');
      const depositTx = await stashContract.depositToken(linkTokenAddress, linkAmount);
      await depositTx.wait();
      console.log('Deposited LINK tokens into Stash contract');
  
    //   // Check stash balance
    //   const stashBalance = await stashContract.balanceOf(signer.address, linkTokenAddress);
    //   console.log('Stash LINK Balance:', ethers.formatUnits(stashBalance, 18));
    // const getSupportedTokens = await stashContract.getSupportedTokens();
    // console.log('getSupportedTokens:', getSupportedTokens);
    } catch (error) {
      console.error('Error:', error);
    }
  }

// Trigger the deposit after a short delay to ensure the event listener is set up
setTimeout(() => {
  triggerDeposit().catch(console.error);
}, 2000);
