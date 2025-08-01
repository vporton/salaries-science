# Science Grants Blockchain

A decentralized grant system for financing fundamental science and open-source software development, built on DFINITY Internet Computer.

## Overview

This project implements a blockchain-based grant system as described in Victor Porton's whitepaper "The High-Level Algorithm of Financing Fundamental Science and Software, for Blockchain Implementation". The system addresses critical issues in funding basic science and software components through:

- **Quadratic funding** mechanism for democratic allocation
- **Dependency-aware distribution** that rewards foundational work
- **Affiliate program** to incentivize marketing and promotion
- **Decentralized consensus** for dependency verification
- **GitCoin Passport integration** for Sybil resistance

## Key Features

### For Project Owners
- Submit scientific papers or software projects
- Automatically receive funds allocated to dependencies
- Track donation statistics and matching funds
- Set donation addresses via GitHub

### For Donors
- Support scientific research and open-source software
- Allocate percentages to dependencies
- Benefit from quadratic funding matching
- Transparent fund distribution

### For Affiliates
- Earn up to 60% commission on donations
- Track performance and earnings
- Access marketing resources
- Persistent rewards for early promotion

### For Servers
- Participate in decentralized dependency verification
- Earn rewards for accurate reporting
- Stake-based consensus mechanism
- Challenge resolution system

## Architecture

The system consists of four main components:

1. **Grants System Canister** (`src/grants_system/`)
   - Manages donations and quadratic matching
   - Handles fund distribution
   - Tracks project statistics

2. **Dependency Graph Canister** (`src/dependency_graph/`)
   - Stores project dependencies
   - Maintains version relationships
   - Validates dependency trees

3. **Consensus Canister** (`src/consensus/`)
   - Server registration and staking
   - Challenge submission and voting
   - Consensus calculation

4. **Frontend Application** (`src/frontend/`)
   - React-based user interface
   - Wallet integration
   - Project discovery and donation flow

## Installation

### Prerequisites

- Node.js 16+ and npm
- DFINITY SDK (dfx)
- Git

### Setup

1. Clone the repository:
```bash
git clone https://github.com/vporton/science-grants-blockchain.git
cd science-grants-blockchain
```

2. Install dependencies:
```bash
npm install
```

3. Install DFINITY SDK:
```bash
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
```

4. Start the local DFINITY replica:
```bash
dfx start --background
```

5. Deploy the canisters:
```bash
dfx deploy
```

6. Start the frontend development server:
```bash
npm run dev
```

## Usage

### Setting Up Your Project

Projects should add a `accounts.json` file to their GitHub repository:

```json
{
  "evm": {
    "defaultAccount": "0x36A0356d43EE4168ED24EFA1CAe3198708667ac0",
    "defaultExpires": "2024-12-31T00:00:00",
    "chains": [
      {
        "chainId": 1,
        "account": "0x36A0356d43EE4168ED24EFA1CAe3198708667ac0",
        "expires": "2024-12-31T00:00:00"
      }
    ]
  }
}
```

Place this file at:
- `https://github.com/USER/USER/.salaries-science/accounts.json` (recommended)
- `https://github.com/USER/PROJECT/.salaries-science/accounts.json` (per-project)

### Making a Donation

1. Connect your Internet Identity wallet
2. Browse available projects
3. Select a project and click "Donate"
4. Configure:
   - Donation amount
   - Dependency allocation percentage (default: 50%)
   - Optional affiliate address
5. Confirm the transaction

### Becoming an Affiliate

1. Connect your wallet
2. Navigate to the Affiliate section
3. Copy your unique affiliate link
4. Share with your network
5. Track earnings and performance

### Running a Server

1. Connect your wallet
2. Navigate to the Server Dashboard
3. Stake ICP tokens (minimum: 100 ICP)
4. Choose whether to participate in rewards
5. Monitor challenges and participate in consensus

## Development

### Project Structure

```
science-grants-blockchain/
├── src/
│   ├── grants_system/     # Main grants canister
│   ├── dependency_graph/  # Dependency tracking
│   ├── consensus/         # Server consensus
│   └── frontend/          # React application
├── dfx.json              # DFINITY configuration
├── package.json          # Node dependencies
└── README.md            # This file
```

### Building for Production

```bash
npm run build
dfx deploy --network ic
```

### Testing

Run the test suite:
```bash
npm test
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Economic Model

The system implements sophisticated economic mechanisms:

- **Quadratic Funding**: Matching funds amplify community preferences
- **Dependency Rewards**: X% of donations flow to dependencies
- **Affiliate Commission**: Y% for current affiliates, K% for previous affiliates
- **Server Incentives**: Fixed rewards for dependency verification
- **Tax**: Configurable percentage to World Science DAO

## Security Considerations

- Stake-based Sybil resistance for servers
- GitCoin Passport integration for donor verification
- Challenge mechanism for incorrect dependency reporting
- Decentralized consensus prevents single points of failure

## Roadmap

- [ ] Mainnet deployment on Internet Computer
- [ ] Integration with package managers (npm, PyPI, crates.io)
- [ ] Automated dependency scanning
- [ ] Multi-chain support
- [ ] Enhanced analytics dashboard
- [ ] Mobile application

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Victor Porton for the original whitepaper and concept
- DFINITY Foundation for the Internet Computer platform
- GitCoin for quadratic funding innovations
- The open-source community

## Contact

- Project Lead: Victor Porton (ORCID: 0000-0001-7064-7975)
- Website: [science-dao.vporton.name](https://science-dao.vporton.name/)
- Donations: [vporton.github.io/science-dao-donate-app](https://vporton.github.io/science-dao-donate-app/)

## References

1. Victor Porton, "The High-Level Algorithm of Financing Fundamental Science and Software"
2. [World Science DAO](https://science-dao.vporton.name/)
3. [DFINITY Internet Computer](https://internetcomputer.org/)
4. [GitCoin Allo Protocol](https://allo.gitcoin.co/)