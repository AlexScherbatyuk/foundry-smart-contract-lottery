# Foundry Smart Contract Lottery

## Overview

**Raffle is a smart contract lottery that utilizes Chainlink VRF to randomly select winners and Chainlink Automation to initialize a winner pick and restart of the lottery**

This project demonstrates the implementation of a decentralized lottery system using:
- **Chainlink VRF v2.5** for provably fair random number generation
- **Chainlink Automation** for automated lottery execution
- **Foundry** for development, testing, and deployment
- **Solidity 0.8.19** for smart contract development

## Features

- 🎰 **Decentralized Lottery**: Fair and transparent lottery system
- 🔗 **Chainlink Integration**: Uses VRF for randomness and Automation for execution
- 🛡️ **Security**: Implements CEI (Checks, Effects, Interactions) pattern
- 🧪 **Comprehensive Testing**: Unit tests with Foundry
- 🚀 **Easy Deployment**: Automated deployment scripts for multiple networks

## Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Node.js and npm (for additional tooling if needed)
- Access to Ethereum RPC endpoints (Sepolia for testnet deployment)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd foundry-smart-contract-lottery
```

2. Install dependencies:
```bash
make install
```

This will install:
- `cyfrin/foundry-devops@0.2.2`
- `smartcontractkit/chainlink-brownie-contracts@1.1.1`
- `foundry-rs/forge-std@v1.8.2`
- `transmissions11/solmate@v6`

## Usage

### Build

```bash
make build
```

### Test

```bash
make test
```

### Format Code

```bash
make fmt
```

### Clean Build Artifacts

```bash
make clean
```

### Generate Test Coverage Snapshot

```bash
make snapshot
```

## Deployment

### Environment Setup

Create a `.env` file with the following variables:
```env
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
PRIVATE_KEY=your_private_key
```

### Deploy to Local Anvil Network

```bash
make deploy
```

### Deploy to Sepolia Testnet

```bash
make deploy-sepolia
```

## Project Structure

```
├── src/
│   └── Raffle.sol              # Main lottery contract
├── test/
│   ├── unit/
│   │   └── RaffleTest.t.sol    # Unit tests
│   ├── integration/            # Integration tests
│   └── mocks/
│       └── LinkToken.sol       # Mock Chainlink token
├── script/
│   ├── DeployRaffle.s.sol      # Deployment script
│   ├── Interactions.s.sol      # Interaction script
│   └── HelperConfig.s.sol      # Configuration helper
├── lib/                        # Dependencies
├── foundry.toml               # Foundry configuration
├── Makefile                   # Build automation
└── README.md                  # This file
```

## Smart Contract Features

### Raffle Contract (`src/Raffle.sol`)

- **Entrance Fee**: Configurable fee to enter the lottery
- **Time Interval**: Configurable time between lottery rounds
- **VRF Integration**: Uses Chainlink VRF for random winner selection
- **Automation**: Uses Chainlink Automation for automated execution
- **State Management**: Tracks lottery state (OPEN/CALCULATING)
- **Winner Selection**: Fair random selection using VRF
- **Prize Distribution**: Automatic prize transfer to winner

### Key Functions

- `enterRaffle()`: Enter the lottery by paying the entrance fee
- `checkUpkeep()`: Check if lottery is ready for winner selection
- `performUpkeep()`: Trigger winner selection process
- `fulfillRandomWords()`: Handle VRF callback and select winner

## Testing

The project includes comprehensive unit tests covering:
- Lottery entry functionality
- Winner selection process
- VRF integration
- Automation triggers
- Error handling
- State management

Run tests with:
```bash
make test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License.

## Acknowledgments

- [Chainlink](https://chainlinklabs.com/) for VRF and Automation services
- [Foundry](https://getfoundry.sh/) for the development framework
- [Cyfrin](https://www.cyfrin.io/) for development best practices