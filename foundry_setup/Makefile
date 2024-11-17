# Include .env file
-include .env

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install the dependencies
install :; forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install OpenZeppelin/openzeppelin-contracts@v5.0.0 --no-commit

# Update Dependencies
update:; forge update

# Compile
build  :; forge build

# Compile using debug mode
debug  :; forge build --debug

# Test
test   :; forge test 

# Test with traces
trace   :; forge test -vvv

# Test with extra traces
trace-extra   :; forge test -vvvv

# Run specific test
test-specific :; forge test --match-test ${TEST}

# Run specific test contract
test-contract :; forge test --match-contract ${CONTRACT}

# Run coverage test
coverage :; forge coverage

# Format code
format :; forge fmt

# Run local node
anvil :; anvil -m 'test test test test test test test test test test test junk'

# Deploy to Anvil
deploy-anvil :; @forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# Deploy to Sepolia
deploy-sepolia :; @forge script script/Deploy.s.sol:DeployScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# # Deploy to Base Sepolia
# deploy-local :; @forge script script/DeployLocal.s.sol:DeployScript \
# 	--rpc-url 127.0.0.1:8545 \
# 	--private-key ${PRIVATE_KEY} \
# 	--broadcast \
# 	-vvvv \
# 	--chain-id 1

# Deploy to local anvil
deploy-ethereum-mainnet:
	forge script script/Deploy.s.sol:DeployScript \
	--rpc-url https://rpc.mevblocker.io \
	--private-key ${PRIVATE_KEY} \
    --broadcast \
	-vvvvv \
	--chain-id 1

# Deploy to local anvil
deploy-local-ethereum-mainnet:
	forge script script/DeployLocal.s.sol:DeployScript \
	--rpc-url http://127.0.0.1:8545 \
	--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast \
	-vvvvv \
	--chain-id 1 \
    --ffi

deploy-local-polygon-mainnet:
	forge script script/DeployLocal.s.sol:DeployScript \
	--rpc-url http://localhost:8081 \
	--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast \
	-vvvvv \
	--chain-id 137

deploy-tenderly-ethereum-mainnet:
	forge script script/Deploy.s.sol:DeployScript \
    --rpc-url ${TENDERLY__VIRTUALIZEMAINNET_RPC_URL} \
    --private-key ${PRIVATE_KEY}  \
    --etherscan-api-key ${TENDERLY_ACCESS_KEY} \
    --broadcast \
    -vvvvv \
    --chain-id 1 \
    --slow \
    --verify \
    --verifier custom \
    --verifier-url ${TENDERLY_VERIFIER_URL} \

# Environment Variables verification
check-env:
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "PRIVATE_KEY is not set"; exit 1; fi
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then echo "ETHERSCAN_API_KEY is not set"; exit 1; fi
	@if [ -z "$(SEPOLIA_RPC_URL)" ]; then echo "SEPOLIA_RPC_URL is not set"; exit 1; fi

# Help
help:
	@echo "Usage:"
	@echo "  make install    - Install project dependencies"
	@echo "  make build      - Compile contracts"
	@echo "  make test       - Run tests"
	@echo "  make trace      - Run tests with traces"
	@echo "  make anvil      - Run local node"
	@echo "  make deploy-sepolia - Deploy to Sepolia"
	@echo "  make deploy-base    - Deploy to Base"
	@echo "  make format     - Format code"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make coverage   - Run coverage tests"

# Verify Sepolia Contracts
verify-sepolia-sales :; forge verify-contract ${SEPOLIA_SALES} src/Sales.sol:Sales \
    --chain-id 11155111 \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --compiler-version v0.8.20 \
    --watch

verify-sepolia-stash :; forge verify-contract ${SEPOLIA_STASH} src/Stash.sol:Stash \
    --chain-id 11155111 \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --compiler-version v0.8.20 \
    --constructor-args $(cast abi-encode "constructor(address)" 0x0000000000000000000000000000000000000000) \
    --watch

verify-sepolia-trade :; forge verify-contract ${SEPOLIA_TRADE} src/Trade.sol:Trade \
    --chain-id 11155111 \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --compiler-version v0.8.20 \
    --constructor-args $(cast abi-encode "constructor(address,address,address)" ${SEPOLIA_STASH} 0x0000000000000000000000000000000000000000 ${SEPOLIA_SALES}) \
    --watch

verify-sepolia-pool :; forge verify-contract ${SEPOLIA_POOL} src/Pool.sol:Pool \
    --chain-id 11155111 \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --compiler-version v0.8.20 \
    --constructor-args $(cast abi-encode "constructor(address,address,address)" ${SEPOLIA_STASH} ${SEPOLIA_TRADE} ${SEPOLIA_SALES}) \
    --watch

verify-sepolia-adapter :; forge verify-contract ${SEPOLIA_ADAPTER} src/adapters/UniswapV3Adapter.sol:UniswapV3Adapter \
    --chain-id 11155111 \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --compiler-version v0.8.20 \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD ${SEPOLIA_POOL}) \
    --watch

# Verify all contracts on each network
verify-all-sepolia: verify-sepolia-sales verify-sepolia-stash verify-sepolia-trade verify-sepolia-pool verify-sepolia-adapter
verify-all-base: verify-base-sales verify-base-stash verify-base-trade verify-base-pool verify-base-adapter


# # Initial setup
# make install
# make build

# # Development cycle
# make test
# make trace-extra # if test fails and you need more info

# # Deployment
# source .env
# make check-env # verify your env vars are set
# make deploy-sepolia

