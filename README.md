# Sui Gacha

A Sui Move package with TypeScript code generation support.

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

