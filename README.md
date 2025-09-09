# Timeboost Smart Contracts

This directory contains the smart contracts that power the decentralized Timeboost protocol. These contracts run on Ethereum-compatible blockchains and provide the foundation for secure, decentralized time synchronization.

## Table of Contents

- [Background](#background)
- [What Are These Contracts For?](#what-are-these-contracts-for)
- [Handling Upgradeability](#handling-upgradeability)
- [The Contracts](#the-contracts)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Security](#security)
- [Getting Help](#getting-help)

## Background
Smart contracts are executable code, deployed on blockchains that 
can be read from / written to anyone with an internet connection. 
Transaction data and smart contract storage is public and can be 
accessed in blockchain explorers. In decentralized Timeboost, 
smart contracts are used to allow anyone to interact with various 
parts of the protocol. This readme is directed at developers who are 
contributing to or making use of this decentralized timeboost 
implementation. 

## What Are These Contracts For?

Timeboost needs a way to coordinate cryptographic keys and committee members across a decentralized network. These smart contracts provide:

- **Key Management**: Store and manage public keys for the protocol
- **Committee Coordination**: Track which nodes are part of the consensus committee
- **Access Control**: Ensure only authorized parties can update critical protocol parameters
- **Transparency**: All changes are recorded on-chain for public verification

These contracts act as the "coordination layer" that allows the Timeboost network to operate without a central authority.

## Handling Upgradeability

### The Upgrade Problem
Once deployed, smart contracts can't be changed. To solve this, we use a proxy solution that functions as upgradeable contracts. 

### The Proxy Solution
We use a "proxy pattern" that works like this:

1. **Users always interact with the proxy** - This address never changes
2. **The proxy points to an implementation** - This can be updated
3. **When you upgrade** - Just point the proxy to a new implementation
4. **All data stays safe** - Storage is preserved across upgrades

Think of it like changing the engine in a car - the car (proxy) stays the same, but you can swap out the engine (implementation) for a better one.

### Our Architecture
```
User → Proxy Contract → Implementation Contract
                    ↓
                Storage (persistent)
```

## The Contracts

### KeyManager - The Main Contract

**What it stores:**
- **Encryption keys** - The cryptographic keys used by the protocol
- **Committee members** - Who's currently in the consensus committee
- **Manager address** - Who can update the contract

**What it does:**
- **Sets committees** - Updates which nodes are part of the network
- **Manages keys** - Stores the threshold encryption key
- **Controls access** - Only the manager can make changes
- **Logs everything** - All changes are recorded as events

**Key functions:**
- `setNextCommittee()` - Add a new committee with future members
- `currentCommitteeId()` - Find which committee is active right now
- `getCommitteeById()` - Get details about a specific committee
- `setThresholdEncryptionKey()` - Set the encryption key for the protocol

### ERC1967Proxy - The Upgrade Mechanism
This is the "shell" that makes upgrades possible:

- **Never changes** - Users always interact with this address
- **Delegates calls** - Forwards requests to the current implementation
- **Preserves data** - All storage survives upgrades
- **SecOps Precautions** - it's important to call the initialize methods during deploys and upgrades so that those transactions aren't front-run

## Getting Started

### Prerequisites

Before you begin, make sure you have:

- **Foundry** - For building, testing, and deploying contracts
  ```bash
  # Install Foundry
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```

### Building the Contracts
```bash
# Build all contracts
just build-contracts

# Or use forge directly
forge build
```

### Testing
```bash
# Run all tests
just test-contracts

# Run with detailed output
forge test -vvv

# Run specific test
forge test --match-test test_setThresholdEncryptionKey
```

### Integration Testing
For testing contract interactions from Rust code, see the [timeboost-contract README](https://github.com/EspressoSystems/timeboost/tree/main/timeboost-contract/README.md) in the Rust repository.

## Deployment

You can deploy to a local anvil network (as done in the test), a fork of a real network, a testnet network (e.g. Ethereum Sepolia) or a mainnet (e.g. Ethereum Mainnet).

### Quick Start (Local Testing)

1. **Set up your environment:**
   ```bash
   cp env.example .env
   # Edit .env with your values
   ```

2. **Start a local blockchain (not needed if using remote rpc):**
   ```bash
   anvil
   ```

3. **Deploy the contracts:**
   ```bash
   ./script/deploy.sh
   ```

That's it! The script will deploy your contracts and show you the addresses.

### Production Deployment

For production deployments, ensure you have:

1. **A secure wallet** with sufficient ETH for gas fees
2. **A valid manager address** (preferably a multisig wallet)
3. **The correct RPC URL** for your target network
4. **Tested thoroughly** on testnets first

### What You Need

- **Manager Address**: Who will manage the contract (usually a multisig wallet)
- **RPC URL**: Where to deploy (localhost for testing, or a real network)
- **Mnemonic**: Your wallet phrase (optional for local testing)

### How It Works

The script deploys two contracts:
1. **KeyManager** - The actual contract with your business logic
2. **Proxy** - Points to the KeyManager, so you can upgrade it later

The proxy gets initialized with your manager address, and that's it!

### Configuration

All settings go in your `.env` file. Copy `env.example` to `.env` and customize:

```bash
# Required: Who manages the contract (use a multisig for production)
MANAGER_ADDRESS=0x1234567890123456789012345678901234567890

# Optional: Where to deploy (defaults to localhost)
RPC_URL=http://localhost:8545

# Optional: Your wallet phrase (defaults to Anvil's test account)
MNEMONIC="your twelve word mnemonic phrase here"
ACCOUNT_INDEX=0
```

**Example configurations:**

- **Local testing**: Use Anvil's default account (no mnemonic needed)
- **Testnet**: Use a test wallet with testnet ETH
- **Mainnet**: Use a secure multisig wallet

### Deployment Process

The deployment script:
1. **Deploys** the KeyManager implementation contract
2. **Creates** an ERC1967 proxy pointing to the implementation
3. **Initializes** the proxy with your manager address
4. **Verifies** the deployment was successful
5. **Returns** both proxy and implementation addresses

### Troubleshooting

**"Manager address not set"**
- Make sure you have `MANAGER_ADDRESS=0x...` in your `.env` file

**"Deployment failed"**
- Check your RPC URL works
- Make sure your wallet has enough ETH for gas
- Verify your mnemonic is correct

**Need help?**
- Make sure Foundry is installed: `forge --version`
- Check your `.env` file has all required values

## Security

### Current Status
- **ERC1967Proxy** - Audited by OpenZeppelin, widely used
- **KeyManager** - Not yet audited (audit planned)

### Security Considerations
- **Manager privileges** - The manager can update committees and keys
- **Upgrade authority** - Only the contract owner can upgrade
- **Committee validation** - Contracts validate committee transitions
- **Event logging** - All changes are logged onchain for transparency

### Best Practices
- **Use multisig wallets** - Don't use single-key wallets for manager/owner
- **Test thoroughly** - Always test on testnets first
- **Monitor events** - Watch for unexpected contract changes
- **Keep keys secure** - Store private keys and mnemonics safely

## Quick Reference

### Common Commands
```bash
# Build contracts
forge build

# Run tests
forge test

# Deploy locally
anvil
./script/deploy.sh

# Run specific test
forge test --match-test test_setThresholdEncryptionKey
```

### Important Addresses
- **Proxy Contract**: The address users interact with (never changes)
- **Implementation Contract**: The actual contract logic (can be upgraded)
- **Manager**: The address that can update committees and keys

## Getting Help
- Review the [timeboost-contract README](https://github.com/EspressoSystems/timeboost/tree/main/timeboost-contract/README.md) in the Rust repo for integration questions
- Check the troubleshooting section above for deployment issues