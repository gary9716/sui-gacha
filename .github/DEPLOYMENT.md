# Deployment Guide

This document describes how to configure and use the CI/CD pipeline for deploying the Sui Move package.

## Required GitHub Secrets

To enable deployments, you need to configure the following secrets in your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:

### Devnet
- `DEVNET_ACTIVE_ADDRESS` - (Optional) The Sui address to use for devnet deployments
- `DEVNET_PRIVATE_KEY` - (Optional) Private key for signing transactions (JSON format from `sui keytool export`)
- `DEVNET_MNEMONIC` - (Optional) Mnemonic phrase for the wallet (alternative to private key)

### Testnet
- `TESTNET_ACTIVE_ADDRESS` - (Optional) The Sui address to use for testnet deployments
- `TESTNET_PRIVATE_KEY` - (Optional) Private key for signing transactions (JSON format from `sui keytool export`)
- `TESTNET_MNEMONIC` - (Optional) Mnemonic phrase for the wallet (alternative to private key)

### Mainnet
- `MAINNET_ACTIVE_ADDRESS` - (Optional) The Sui address to use for mainnet deployments
- `MAINNET_PRIVATE_KEY` - (Optional) Private key for signing transactions (JSON format from `sui keytool export`)
- `MAINNET_MNEMONIC` - (Optional) Mnemonic phrase for the wallet (alternative to private key)

**Note**: You need to provide either a private key or mnemonic for each network to enable deployments. The active address is optional and will be auto-detected if you provide a key/mnemonic.

## How to Export Your Private Key

To export your private key for use in CI/CD:

1. Install Sui CLI locally
2. Run `sui keytool export <key-name>` to export a key in JSON format
3. Copy the JSON output and add it as a secret (e.g., `DEVNET_PRIVATE_KEY`)
4. Alternatively, you can use your mnemonic phrase directly

**Security Warning**: Never commit private keys or mnemonics to the repository. Always use GitHub Secrets.

## Workflow Structure

The CI/CD is split into separate workflow files:

- **`test.yml`** - Runs tests on every push and pull request
- **`deploy-devnet.yml`** - Deploys to devnet
- **`deploy-testnet.yml`** - Deploys to testnet
- **`deploy-mainnet.yml`** - Deploys to mainnet
- **`publish-ts-package.yml`** - Publishes TypeScript/npm package

## Workflow Triggers

### Automatic Triggers

1. **Tests** (`test.yml`): 
   - Run automatically on every push and pull request to `main` or `develop` branches

### Manual Triggers

All deployment workflows are **manual only** and must be triggered via GitHub Actions UI:

1. **Devnet Deployment** (`deploy-devnet.yml`):
   - Go to **Actions** → **Deploy to Devnet** → **Run workflow**
   - Click **Run workflow**
   - Runs tests first, then deploys if tests pass

2. **Testnet Deployment** (`deploy-testnet.yml`):
   - Go to **Actions** → **Deploy to Testnet** → **Run workflow**
   - Click **Run workflow**
   - Runs tests first, then deploys if tests pass

3. **Mainnet Deployment** (`deploy-mainnet.yml`):
   - Go to **Actions** → **Deploy to Mainnet** → **Run workflow**
   - Click **Run workflow**
   - Runs tests first, then deploys if tests pass


## Environment Protection

The workflow uses GitHub Environments for deployments:
- `devnet` - For devnet deployments
- `testnet` - For testnet deployments (can be protected)
- `mainnet` - For mainnet deployments (should be protected)

You can add environment protection rules in **Settings** → **Environments** to require approvals for testnet/mainnet deployments.

## npm Publishing

The project includes a publish workflow (`publish-ts-package.yml`) to publish the npm package:

### Manual Publishing

1. Go to **Actions** → **Publish TypeScript Package** → **Run workflow**
2. Select version bump type (patch, minor, or major)
3. Click **Run workflow**
4. The workflow will:
   - Run tests
   - Generate TypeScript code
   - Bump version in package.json
   - Publish to npm
   - Create a GitHub release

### Tag-Based Publishing

Push a tag starting with `v` (e.g., `v1.0.0`) to trigger automatic publishing:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Required Secrets

For npm publishing, add the following secret:
- `NPM_TOKEN` - Your npm access token with publish permissions

To create an npm token:
1. Go to https://www.npmjs.com/settings/YOUR_USERNAME/tokens
2. Create a new "Automation" token
3. Add it as `NPM_TOKEN` in GitHub Secrets

**Note**: The npm environment uses GitHub's built-in authentication, but you still need `NPM_TOKEN` for publishing to the public npm registry.

## Viewing Deployment Results

After a deployment completes:
1. Check the workflow run in the **Actions** tab
2. The package ID will be displayed in the workflow logs

