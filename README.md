# Decentralized Voting System

A Clarity smart contract for creating and voting in decentralized polls on Stacks.

## Overview
This project allows users to:
- Create polls with a question (up to 100 characters).
- Vote "yes" or "no" on polls (one vote per user per poll).
- View poll results.

## Contract Details
- **File**: `voting-system.clar`
- **Functions**:
  - `(create-poll question)`: Creates a new poll.
  - `(vote poll-id is-yes)`: Casts a vote on a poll.
  - `(get-poll poll-id)`: Retrieves poll details.

## Getting Started
1. Clone the repository.
2. Run `clarinet check` to verify the contract.
3. Deploy to a Stacks testnet.
4. Develop a front-end for poll creation and voting.

## Testing
Run tests with:
```bash
clarinet test