#!/bin/bash

# Internet Identity Deployment Script for Localhost
# This script sets up Internet Identity canister on your local DFX network

set -e

echo "🚀 Starting Internet Identity deployment on localhost..."

# Check if dfx is installed
if ! command -v dfx &> /dev/null; then
    echo "❌ DFX is not installed. Please install DFX first:"
    echo "   sh -ci \"\$(curl -fsSL https://internetcomputer.org/install.sh)\""
    exit 1
fi

# Start the local network if not running
echo "📡 Starting local DFX network..."
dfx start --background --clean

# Wait for the network to be ready
echo "⏳ Waiting for local network to be ready..."
sleep 10

# Deploy Internet Identity canister
echo "🔐 Deploying Internet Identity canister..."
dfx deploy internet_identity

# Get the canister ID
CANISTER_ID=$(dfx canister id internet_identity)
echo "✅ Internet Identity deployed with canister ID: $CANISTER_ID"

# Create a configuration file for the frontend
echo "📝 Creating configuration file..."
cat > .env.local << EOF
# Internet Identity Configuration
INTERNET_IDENTITY_CANISTER_ID=$CANISTER_ID
INTERNET_IDENTITY_URL=http://localhost:4943/?canisterId=$CANISTER_ID
EOF

echo "🎉 Internet Identity deployment completed!"
echo ""
echo "📋 Next steps:"
echo "1. Access Internet Identity at: http://localhost:4943/?canisterId=$CANISTER_ID"
echo "2. Create your first identity anchor"
echo "3. Use the canister ID '$CANISTER_ID' in your frontend application"
echo ""
echo "🔧 To stop the local network: dfx stop"