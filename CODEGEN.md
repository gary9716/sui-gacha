# TypeScript Code Generation

This project uses `@mysten/codegen` to automatically generate TypeScript code from the Move package, enabling type-safe interactions with your Move modules.

## Setup

1. **Install dependencies:**
   ```bash
   make install-deps
   # or
   npm install
   ```

2. **Generate TypeScript code:**
   ```bash
   make codegen
   # or
   npm run codegen
   ```

   This will:
   - Build the Move package
   - Generate package summaries using `sui move summary`
   - Generate TypeScript code in `src/generated/`

## Usage

### Watch Mode

To automatically regenerate code when Move files change:

```bash
make codegen-watch
# or
npm run codegen:watch
```

### Using Generated Code

The generated TypeScript code will be available in `src/generated/`. You can import and use it in your TypeScript/JavaScript projects:

```typescript
import { Transaction } from '@mysten/sui/transactions';
import * as gacha from './generated/gacha/gacha';

// Example: Call a function from your Move module
async function callMoveFunction() {
  const tx = new Transaction();
  
  // Use generated functions
  tx.add(gacha.someFunction({
    arguments: {
      // Type-safe arguments
    },
  }));

  const { digest } = await suiClient.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
  });

  return digest;
}
```

### Configuring SuiClient for Local Packages

Since this package uses `@local-pkg/gacha`, you need to configure your `SuiClient` with the package ID override:

```typescript
import { SuiClient } from '@mysten/sui/client';

const client = new SuiClient({
  network: 'testnet', // or 'devnet', 'mainnet'
  url: 'https://fullnode.testnet.sui.io:443',
  mvr: {
    overrides: {
      packages: {
        '@local-pkg/gacha': 'YOUR_PACKAGE_ID', // Replace with actual package ID
      },
    },
  },
});
```

Replace `YOUR_PACKAGE_ID` with the actual package ID after deployment.

## Configuration

The codegen configuration is in `sui-codegen.config.ts`:

- `output`: Directory where generated code will be written
- `generateSummaries`: Whether to generate package summaries
- `prune`: Whether to remove old generated files
- `packages`: List of Move packages to generate code for

## CI/CD

The codegen step is automatically run in the test workflow to ensure:
- Generated code is always up-to-date
- TypeScript compilation succeeds
- No breaking changes are introduced

## Troubleshooting

### Package summaries not found

If you get errors about missing package summaries:

1. Ensure you've built the Move package: `make build`
2. Generate summaries: `sui move summary`
3. Then run codegen: `make codegen`

### Generated code is outdated

If the generated code doesn't match your Move code:

1. Clean build artifacts: `make clean`
2. Rebuild: `make build`
3. Regenerate: `make codegen`

### TypeScript errors

If you see TypeScript errors in generated code:

1. Ensure you have the latest `@mysten/codegen` version
2. Check that your Move code compiles without errors
3. Try regenerating: `make codegen`

