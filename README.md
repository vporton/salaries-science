# grants-science

A decentralized science funding platform built on the Internet Computer.

## Features

- Decentralized salary management for scientific research
- Internet Identity authentication
- Blockchain-based consensus mechanism
- Modern web interface

## Quick Start

### Prerequisites

- [DFX](https://internetcomputer.org/docs/current/developer-docs/setup/install/) (version 0.15.0 or later)
- Node.js and npm
- A modern web browser with WebAuthn support

### Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd grants-science
   ```

2. **Deploy Internet Identity (required for authentication):**
   ```bash
   ./deploy-internet-identity.sh
   ```

3. **Deploy the application:**
   ```bash
   dfx deploy
   ```

4. **Start the frontend:**
   ```bash
   dfx start --background
   ```

## Documentation

- [Internet Identity Setup Guide](INTERNET_IDENTITY_SETUP.md) - Complete guide for setting up authentication
- [Science Grants Blockchain Documentation](science-grants-blockchain/README.md) - Detailed documentation for the blockchain components

## Project Structure

```
├── dfx.json                          # Main DFX configuration
├── deploy-internet-identity.sh       # Internet Identity deployment script
├── INTERNET_IDENTITY_SETUP.md        # Internet Identity documentation
├── science-grants-blockchain/        # Core blockchain implementation
│   ├── dfx.json                      # Blockchain DFX configuration
│   ├── src/                          # Motoko source code
│   └── README.md                     # Blockchain documentation
└── src/salaries_frontend/            # Frontend application
```

## Development

### Local Development

1. Start the local network:
   ```bash
   dfx start --background --clean
   ```

2. Deploy Internet Identity:
   ```bash
   dfx deploy internet_identity
   ```

3. Deploy your canisters:
   ```bash
   dfx deploy
   ```

### Testing

```bash
dfx test
```

## Contributing

Please read [CODE-OF-CONDUCT.md](CODE-OF-CONDUCT.md) before contributing.

## License

This project is licensed under the terms specified in [LICENSE.txt](LICENSE.txt).
