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

## Workflow Triggers

### Automatic Triggers

1. **Tests**: Run automatically on every push and pull request
2. **Devnet Deployment**: 
   - Automatically runs on push to `main` or `develop` branches
   - Only runs if tests pass

### Manual Triggers

1. **Testnet Deployment**:
   - Go to **Actions** → **CI/CD Pipeline** → **Run workflow**
   - Select `testnet` from the network dropdown
   - Click **Run workflow**

2. **Mainnet Deployment**:
   - Go to **Actions** → **CI/CD Pipeline** → **Run workflow**
   - Select `mainnet` from the network dropdown
   - Click **Run workflow**

### Tag-Based Triggers

- **Testnet**: Push a tag starting with `v` (e.g., `v1.0.0`) to trigger testnet deployment
- **Mainnet**: Push a tag starting with `release-` (e.g., `release-1.0.0`) to trigger mainnet deployment

## Environment Protection

The workflow uses GitHub Environments for deployments:
- `devnet` - For devnet deployments
- `testnet` - For testnet deployments (can be protected)
- `mainnet` - For mainnet deployments (should be protected)

You can add environment protection rules in **Settings** → **Environments** to require approvals for testnet/mainnet deployments.

## Viewing Deployment Results

After a deployment completes:
1. Check the workflow run in the **Actions** tab
2. The package ID will be displayed in the workflow logs
3. For PRs, the package ID will be posted as a comment
4. For tagged releases, a GitHub release will be created with the package ID

