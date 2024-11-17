const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { ethers } = require('ethers');
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { log } = require('console');

const app = express();
app.use(express.json());

// MongoDB User Schema
const UserSchema = new mongoose.Schema({
    address: {
        type: String,
        required: true,
        unique: true,
    },
    password: {
        type: String,
        required: true
    }
});

const User = mongoose.model('User', UserSchema);

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

// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    console.log(authHeader);
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: 'Access token required' });

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid token' });
        req.user = user;
        next();
    });
};

const TradeABI = JSON.parse(fs.readFileSync(path.join(__dirname, '../abis/Trade.json')));

// Initialize Ethereum contract connections
const provider = new ethers.JsonRpcProvider(process.env.ETHEREUM_RPC_URL);
const tradeContract = new ethers.Contract(
    process.env.TRADE_CONTRACT_ADDRESS,
    TradeABI,
    new ethers.Wallet(process.env.PRIVATE_KEY, provider)
);

// Register endpoint
app.post('/api/register', async (req, res) => {
    try {
        const { address, password } = req.body;

        // Validate Ethereum address
        if (!ethers.isAddress(address)) {
            return res.status(400).json({ error: 'Invalid Ethereum address' });
        }

        // Check if user exists
        const existingUser = await User.findOne({ address });
        if (existingUser) {
            return res.status(400).json({ error: 'Address already registered' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create user
        const user = new User({
            address,
            password: hashedPassword
        });

        await user.save();

        res.status(201).json({ message: 'Registration successful' });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
    try {
        const { address, password } = req.body;

        // Find user
        const user = await User.findOne({ address });
        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Check password
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Generate JWT
        const token = jwt.sign(
            { address: user.address },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({ token });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

// Execute trade endpoint
app.post('/api/trade', authenticateToken, async (req, res) => {
    try {
        const {
            dexName,
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            deadline = Math.floor(Date.now() / 1000) + 3600 // 1 hour from now
        } = req.body;

        // Find the current balance document
        let balanceDoc = await Balance.findOne({
            user: req.user.address,
            token: tokenIn
        });

        if (!balanceDoc || balanceDoc.balance < amountIn) {
            return res.status(400).json({ error: 'Insufficient balance' });
        }

        // Validate input
        if (!ethers.isAddress(tokenIn) || !ethers.isAddress(tokenOut)) {
            return res.status(400).json({ error: 'Invalid token address' });
        }

        // Execute trade using the owner's private key
        const tx = await tradeContract.executeTrade(
            dexName,
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            deadline,
            req.user.address  // User's address from JWT
        );

        const receipt = await tx.wait();

        res.json({
            success: true,
            txHash: receipt.hash
        });
    } catch (error) {
        console.error('Trade error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Connect to MongoDB and start server
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/trade_monitor')
    .then(() => {
        console.log('Connected to MongoDB');
        const PORT = process.env.PORT || 3001;
        app.listen(PORT, () => {
            console.log(`API Server running on port ${PORT}`);
        });
    })
    .catch(err => console.error('MongoDB connection error:', err));