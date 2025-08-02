# Internet Identity Setup for Localhost

This guide explains how to set up and use Internet Identity canister on your local DFX network.

## What is Internet Identity?

Internet Identity is a decentralized identity provider for the Internet Computer that allows users to authenticate with dApps using WebAuthn-compatible devices (like biometric authentication on your phone or computer).

## Prerequisites

- DFX installed (version 0.15.0 or later)
- A modern web browser with WebAuthn support
- A WebAuthn-compatible device (fingerprint reader, face ID, etc.)

## Quick Setup

1. **Run the deployment script:**
   ```bash
   ./deploy-internet-identity.sh
   ```

2. **Access Internet Identity:**
   - Open your browser and navigate to the URL provided by the script
   - It will look like: `http://localhost:4943/?canisterId=<canister-id>`

3. **Create your first identity:**
   - Click "Create Internet Identity"
   - Follow the prompts to set up your device
   - Note down your identity anchor number

## Manual Setup

If you prefer to set up manually:

1. **Start the local network:**
   ```bash
   dfx start --background --clean
   ```

2. **Deploy Internet Identity:**
   ```bash
   dfx deploy internet_identity
   ```

3. **Get the canister ID:**
   ```bash
   dfx canister id internet_identity
   ```

## Using Internet Identity in Your Application

### Frontend Integration

1. **Install the Internet Identity library:**
   ```bash
   npm install @dfinity/auth-client @dfinity/identity
   ```

2. **Initialize the auth client:**
   ```javascript
   import { AuthClient } from '@dfinity/auth-client';
   import { InternetIdentity } from '@dfinity/auth-client/lib/cjs/identity/internet-identity';

   const authClient = await AuthClient.create();
   ```

3. **Configure Internet Identity:**
   ```javascript
   const internetIdentity = new InternetIdentity({
     identityProvider: 'http://localhost:4943/?canisterId=<your-canister-id>'
   });
   ```

### Backend Integration (Motoko)

1. **Add Internet Identity dependency to your `mops.toml`:**
   ```toml
   [dependencies]
   internet_identity = "0.1.0"
   ```

2. **Import and use in your Motoko code:**
   ```motoko
   import InternetIdentity "mo:internet_identity";
   
   // Your canister logic here
   ```

## Configuration

The deployment script creates a `.env.local` file with:
- `INTERNET_IDENTITY_CANISTER_ID`: The canister ID of your local Internet Identity
- `INTERNET_IDENTITY_URL`: The URL to access Internet Identity

## Troubleshooting

### Common Issues

1. **"DFX is not installed"**
   - Install DFX: `sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"`

2. **WebAuthn not working**
   - Ensure you're using HTTPS or localhost
   - Check that your device supports WebAuthn
   - Try a different browser

3. **Canister deployment fails**
   - Check that the local network is running: `dfx ping`
   - Restart the network: `dfx stop && dfx start --background --clean`

### Reset Internet Identity

To reset your local Internet Identity:

```bash
dfx stop
dfx start --background --clean
dfx deploy internet_identity
```

## Security Notes

- The local Internet Identity is for development only
- Never use local canister IDs in production
- Always use the official Internet Identity canister on mainnet for production applications

## Additional Resources

- [Internet Identity Documentation](https://internetcomputer.org/docs/current/developer-docs/integrations/internet-identity/)
- [DFX Documentation](https://internetcomputer.org/docs/current/developer-docs/setup/install/)
- [WebAuthn Specification](https://www.w3.org/TR/webauthn/)

## Support

If you encounter issues:
1. Check the DFX logs: `dfx logs internet_identity`
2. Verify your DFX version: `dfx --version`
3. Ensure your browser supports WebAuthn