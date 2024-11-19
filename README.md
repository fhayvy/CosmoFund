# CosmoFund: Decentralized Crowdfunding for Space Exploration

CosmoFund is a decentralized platform that enables individuals to contribute to and vote on space exploration projects. The platform uses smart contracts to manage funds and decision-making processes, ensuring transparency and community involvement in space exploration initiatives.

## Features

- Decentralized crowdfunding for space exploration projects
- Voting mechanism for project selection and fund allocation
- Transparent fund management through smart contracts
- Project proposal submission and review process
- Reward system for contributors based on project success
- Project cancellation by creators (if no contributions have been made)
- Dynamic deadline extensions based on project progress

## Smart Contract

The core functionality of CosmoFund is implemented in a Clarity smart contract. Here's an overview of the main functions:

- `submit-project`: Allows users to submit new space exploration project proposals
- `contribute`: Enables users to contribute funds to specific projects
- `vote`: Allows contributors to vote on project proposals
- `withdraw-funds`: Permits project creators to withdraw funds if the project reaches its funding goal
- `refund`: Allows contributors to get a refund if a project doesn't meet its funding goal
- `cancel-project`: Enables project creators to cancel their projects if no contributions have been made
- `extend-deadline`: Allows project creators to extend the deadline under specific conditions

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): A Clarity runtime packaged as a command line tool
- [Node.js](https://nodejs.org/) (v14 or later)
- [Stacks Wallet](https://www.hiro.so/wallet) for interacting with the Stacks blockchain

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/cosmofund.git
   cd cosmofund
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Deploy the smart contract (make sure you have Clarinet set up):
   ```
   clarinet deploy
   ```

## Usage

1. Submit a project proposal:
   ```
   clarinet console
   (contract-call? .cosmofund submit-project "Mars Rover 2030" u1000000000 u31536000)
   ```

2. Contribute to a project:
   ```
   (contract-call? .cosmofund contribute u1 u100000000)
   ```

3. Vote on a project:
   ```
   (contract-call? .cosmofund vote u1 true)
   ```

4. Withdraw funds (for project creators):
   ```
   (contract-call? .cosmofund withdraw-funds u1)
   ```

5. Request a refund (for contributors if a project fails):
   ```
   (contract-call? .cosmofund refund u1)
   ```

6. Cancel a project (for project creators):
   ```
   (contract-call? .cosmofund cancel-project u1)
   ```

7. Extend project deadline (for project creators):
   ```
   (contract-call? .cosmofund extend-deadline u1 u32000000)
   ```

## Dynamic Deadline Extensions

Project creators can extend the deadline of their projects under the following conditions:
- The project has reached at least 75% of its funding goal
- The extension request is made before the current deadline
- The extension is for no more than 30 days
- The project has not been extended more than 3 times

## Contributing

Contributions are welcome to CosmosFund! If you'd like to contribute, please follow these steps:

1. Fork the repository
2. Create your feature branch (git checkout -b feature/AmazingFeature)
3. Commit your changes (git commit -m 'Add some AmazingFeature')
4. Push to the branch (git push origin feature/AmazingFeature)
5. Open a Pull Request

## Acknowledgments

- Thanks to the Stacks community for their support and resources
- Inspired by the ongoing efforts in space exploration and the potential of decentralized technologies