# Sui Gacha

A Sui Move package with TypeScript code generation support for implementing gacha game mechanics on the Sui blockchain.

## What is a Gacha Game?

A **gacha game** is a type of game that incorporates a monetization mechanic where players spend in-game currency (or real money) to obtain random virtual items, characters, or equipment. The term "gacha" originates from Japanese gashapon (ガシャポン) capsule-toy vending machines, where players insert coins and receive a random toy in a capsule.

### Key Components

#### 1. **Banners**
Banners are time-limited events or promotions that feature specific items or characters with increased drop rates. Each banner has:
- A curated pool of available items
- Featured items with boosted probability rates
- Time-limited availability (optional)
- Unique themes or storylines

Banners are rotated regularly to maintain player interest and create urgency.

#### 2. **Pulls**
A "pull" (also called a "summon" or "roll") is the action of spending currency to receive random items from a banner's pool. Players can typically:
- Perform **single pulls** (1 item per pull)
- Perform **multi-pulls** (often 10 items at once, sometimes with guarantees)
- Use different currency types (free currency, premium currency, tickets)

#### 3. **Rarity Tiers**
Items are categorized by rarity levels, typically:
- **Common** (1-2 stars): Most common, ~70-80% drop rate
- **Uncommon** (3 stars): ~15-20% drop rate
- **Rare** (4 stars): ~5-10% drop rate
- **Epic** (5 stars): ~1-3% drop rate
- **Legendary** (6 stars): ~0.1-1% drop rate

Higher rarity items are usually more powerful, unique, or desirable.

#### 4. **Pity System**
The pity system is a guarantee mechanism that ensures players receive high-rarity items after a certain number of unsuccessful pulls. This mitigates frustration from bad luck:

- **Soft Pity**: Gradually increasing rates after X pulls (e.g., starting at pull 75)
- **Hard Pity**: Guaranteed high-rarity item at Y pulls (e.g., guaranteed Epic at 90 pulls)
- **Pity Counter**: Tracks consecutive pulls without receiving high-rarity items
- **Independent Counters**: Separate pity counters for different rarity tiers (e.g., Epic and Legendary)

Pity counters are typically:
- **Player-specific**: Each player has their own independent counters
- **Banner-specific**: Pity is tracked separately for each banner
- **Visible**: Transparent tracking builds trust (especially important for blockchain games)

### Why Blockchain Gacha?

Blockchain-based gacha systems offer unique advantages:

- **Transparency**: All rates, pity counters, and pull results are verifiable on-chain
- **Trust**: Players can verify that rates are fair and not manipulated
- **Ownership**: Items are truly owned by players as NFTs or on-chain assets
- **Interoperability**: Items can potentially be used across multiple games or traded
- **Immutability**: Pull history and pity states are permanently recorded

### Learn More

For more information about gacha game mechanics, see:
- [Gacha Games Explained: Banners, Pulls, Pity Systems, and More](https://store.epicgames.com/en-US/news/gacha-games-explained-banners-pulls-pity-systems-and-more)
- See [DESIGN.md](DESIGN.md) for detailed design documentation of this implementation

## Quick Start

### Prerequisites

- [Sui CLI](https://docs.sui.io/build/install) installed
- Node.js 20+ and npm

### Setup

1. **Install dependencies:**
   ```bash
   make install-deps
   ```

2. **Build the Move package:**
   ```bash
   make build
   ```

3. **Run tests:**
   ```bash
   make test
   ```

4. **Generate TypeScript code:**
   ```bash
   make codegen
   ```

## Available Commands

See `make help` for all available commands, or check the [Makefile](Makefile).

### Common Commands

- `make build` - Build the Move package
- `make test` - Run Move unit tests
- `make codegen` - Generate TypeScript code from Move package
- `make codegen-watch` - Watch for changes and regenerate TypeScript
- `make clean` - Clean build artifacts

## TypeScript Code Generation

This project uses `@mysten/codegen` to generate TypeScript bindings from the Move package. See [CODEGEN.md](CODEGEN.md) for detailed information.

## Project Structure

```
.
├── sources/           # Move source files
├── tests/            # Move test files
├── src/              # TypeScript source (if using generated code)
│   └── generated/   # Generated TypeScript code (auto-generated)
├── Move.toml         # Move package configuration
├── package.json      # Node.js dependencies
├── sui-codegen.config.ts  # Codegen configuration
└── Makefile         # Build commands
```

## CI/CD

This project includes GitHub Actions workflows for:
- **Tests**: Automatically run on push/PR
- **Deployments**: Manual deployment to devnet, testnet, and mainnet

See [.github/DEPLOYMENT.md](.github/DEPLOYMENT.md) for deployment instructions.

## License

MIT

