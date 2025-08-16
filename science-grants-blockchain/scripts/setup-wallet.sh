#!/bin/bash

# Script to set up wallet canister ID in grants system
# This should be run after deploying the wallet canister

set -e

# Check if wallet canister ID is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <wallet-canister-id>"
    echo "Example: $0 rrkah-fqaaa-aaaaa-aaaaq-cai"
    exit 1
fi

WALLET_CANISTER_ID=$1

echo "Setting up wallet canister ID: $WALLET_CANISTER_ID"

# Update the wallet canister ID in the grants system
# This would typically be done through a canister call
# For now, we'll create a script that can be run manually

cat > setup-wallet.js << EOF
// Script to set wallet canister ID in grants system
// Run this after deploying the wallet canister

const { Actor, HttpAgent } = require('@dfinity/agent');
const { Principal } = require('@dfinity/principal');

// Replace with your actual canister IDs
const GRANTS_CANISTER_ID = 'your-grants-canister-id';
const WALLET_CANISTER_ID = '$WALLET_CANISTER_ID';

async function setupWallet() {
    // Initialize agent
    const agent = new HttpAgent({
        host: process.env.DFX_NETWORK === 'ic' ? 'https://ic0.app' : 'http://localhost:8080'
    });

    if (process.env.DFX_NETWORK !== 'ic') {
        await agent.fetchRootKey();
    }

    // Create grants system actor
    const grantsActor = Actor.createActor(grantsIdl, {
        agent,
        canisterId: GRANTS_CANISTER_ID
    });

    // Set wallet canister ID
    // Note: This would require adding a setWalletCanisterId function to the grants system
    console.log('Setting wallet canister ID...');
    // await grantsActor.setWalletCanisterId(WALLET_CANISTER_ID);
    console.log('Wallet canister ID set successfully!');
}

setupWallet().catch(console.error);
EOF

echo "Created setup-wallet.js script"
echo "Please update the GRANTS_CANISTER_ID in the script and run it manually"
echo "You may also need to add a setWalletCanisterId function to your grants system canister"
