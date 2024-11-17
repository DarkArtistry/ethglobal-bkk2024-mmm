// server/index.js
const express = require('express');
const { ethers } = require('ethers');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

dotenv.config();

const app = express();
app.use(express.json());

// Load ABIs
const TradeABI = JSON.parse(fs.readFileSync(path.join(__dirname, '../abis/Trade.json')));
const StashABI = JSON.parse(fs.readFileSync(path.join(__dirname, '../abis/Stash.json')));

// Define simplified Balance schema
const BalanceSchema = new mongoose.Schema({
    user: String,
    token: String,
    balance: {
        type: String,  // Using String to handle large numbers
        default: '0'
    },
    lastUpdated: { 
        type: Date, 
        default: Date.now 
    }
});

// Create compound index for user and token
BalanceSchema.index({ user: 1, token: 1 }, { unique: true });

const Balance = mongoose.model('Balance', BalanceSchema);

// Optional: Transaction history if needed
const TransactionSchema = new mongoose.Schema({
    user: String,
    token: String,
    amount: String,
    txHash: String,
    type: {
        type: String,
        enum: ['deposit', 'withdrawal']
    },
    network: String,  // Keep network in transactions for reference
    timestamp: { 
        type: Date, 
        default: Date.now 
    }
});

const Transaction = mongoose.model('Transaction', TransactionSchema);

// Simplified balance update function
async function updateBalance(user, token, amount, isDeposit) {
    try {
        const filter = { user, token };
        
        // Find the current balance document
        let balanceDoc = await Balance.findOne(filter);
        
        if (!balanceDoc) {
            // If no balance exists, create new with 0 balance
            balanceDoc = new Balance({
                user,
                token,
                balance: '0'
            });
        }

        // Convert to BigInt for accurate calculation
        let currentBalance = BigInt(balanceDoc.balance);
        const amountBigInt = BigInt(amount);

        // Update balance based on operation
        if (isDeposit) {
            currentBalance += amountBigInt;
        } else {
            // Ensure balance won't go negative
            if (currentBalance < amountBigInt) {
                throw new Error('Insufficient balance');
            }
            currentBalance -= amountBigInt;
        }

        // Update or create the balance document
        const result = await Balance.findOneAndUpdate(
            filter,
            {
                $set: {
                    balance: currentBalance.toString(),
                    lastUpdated: new Date()
                }
            },
            {
                new: true,
                upsert: true
            }
        );

        console.log(`Balance updated for user ${user}:`, {
            token,
            newBalance: result.balance,
            operation: isDeposit ? 'deposit' : 'withdraw'
        });

        return result;
    } catch (error) {
        console.error('Error updating balance:', error);
        throw error;
    }
}


// Network configurations
const networks = {
    // polygon: {
    //     rpc: process.env.POLYGON_RPC_URL,
    //     ws: process.env.POLYGON_WS_URL, // Add WebSocket URLs to your .env
    //     tradeAddress: '0x407FB1A641098BDf7a9Ef5a84e910a1F996c700f',
    //     stashAddress: '0xC09DC940D14459184FFb01e3cda3fe084c0c765f',
    //     chainId: 137
    // },
    etheruem: {
        rpc: process.env.ETHEREUM_RPC_URL,
        ws: process.env.ETHEREUM_WS_URL,
        tradeAddress: '0xDBb892634b4ed96C20A711FFa01CcE7C67feb119',
        stashAddress: process.env.STASH_CONTRACT_ADDRESS,
        chainId: 1
    }
};

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/trade_monitor')
    .then(() => console.log('Connected to MongoDB'))
    .catch(err => console.error('MongoDB connection error:', err));

// Schema definitions remain the same...

// Initialize providers and contracts
const providers = {};
const tradeContracts = {};
const stashContracts = {};

let lastProcessedBlock = {}; // Track last processed block for each network

// Alternative event monitoring using polling
async function pollEvents(network) {
    const provider = providers[network];
    const stashContract = stashContracts[network];
    
    try {
        const filter = {
            address: networks[network].stashAddress,
            topics: [
                [
                    ethers.id("TokenDeposited(address,address,uint256)"),
                    ethers.id("TokenWithdrawn(address,address,uint256)")
                ]
            ]
        };

        // Get latest block
        const latestBlock = await provider.getBlockNumber();
        const fromBlock = lastProcessedBlock[network] ? lastProcessedBlock[network] : latestBlock - 1000;
        // Only process if there are new blocks
        if (fromBlock >= latestBlock) return;

        console.log(`Polling ${network} from block ${fromBlock} to ${latestBlock}`);
        

        // Get events
        const events = await provider.getLogs({
            ...filter,
            fromBlock: fromBlock + 1,
            toBlock: latestBlock
        });

        console.log("events: ", events);
        

        for (const event of events) {
            try {
                const parsedLog = stashContract.interface.parseLog({
                    topics: event.topics,
                    data: event.data
                });

                if (parsedLog.name === 'TokenDeposited') {
                    const [user, token, amount] = parsedLog.args;
                    updateBalance(user, token, amount, true)
                    console.log(`Saved deposit event on ${network}`);
                    // Optionally store transaction history
                    await new Transaction({
                        user,
                        token,
                        amount: amount.toString(),
                        network, // Keep network info just for reference
                        txHash: event.transactionHash,
                        type: 'deposit'
                    }).save();
                }

                if (parsedLog.name === 'TokenWithdrawn') {
                    const [user, token, amount] = parsedLog.args;
                    updateBalance(user, token, amount, false)
                    console.log(`Saved withdrawal event on ${network}`);
                    // Optionally store transaction history
                    await new Transaction({
                        user,
                        token,
                        amount: amount.toString(),
                        network, // Keep network info just for reference
                        txHash: event.transactionHash,
                        type: 'withdrawal'
                    }).save();
                }
            } catch (error) {
                console.error(`Error processing event:`, error);
            }
        }

        // Update last processed block
        lastProcessedBlock[network] = latestBlock;
    } catch (error) {
        console.error(`Error polling ${network}:`, error);
    }
}

// Initialize monitoring
async function initializeMonitoring() {
    for (const [network, config] of Object.entries(networks)) {
        try {
            // Initialize provider
            console.log("config.rpc: ", config.rpc);
            console.log("config.ws: ", config.ws);
            
            providers[network] = new ethers.JsonRpcProvider(config.rpc);
            const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || '', providers[network]);
            
            // Initialize contracts
            // tradeContracts[network] = new ethers.Contract(
            //     config.tradeAddress,
            //     TradeABI,
            //     wallet
            // );
            stashContracts[network] = new ethers.Contract(
                config.stashAddress,
                StashABI,
                providers[network]
            );
            
            console.log(`Initialized contracts for ${network}`);

            // Start polling for events
            setInterval(() => pollEvents(network), 30000); // Poll every 30 seconds
            await pollEvents(network); // Initial poll
            
        } catch (error) {
            console.error(`Error initializing ${network}:`, error);
        }
    }
}

// API endpoints remain the same...

// Start server and monitoring
const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
    console.log(`Server running on port ${PORT}`);
    await initializeMonitoring();
});

// Handle process termination
process.on('SIGINT', async () => {
    console.log('Shutting down gracefully...');
    await mongoose.disconnect();
    process.exit(0);
});