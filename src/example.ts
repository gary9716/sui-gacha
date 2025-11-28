/**
 * Example usage of generated TypeScript code from Move package
 * 
 * This file demonstrates how to use the generated TypeScript bindings
 * to interact with your Move modules.
 * 
 * Note: After running `make codegen`, import from './generated/sui_gacha/sui_gacha'
 */

import { Transaction } from '@mysten/sui/transactions';
import { SuiClient } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';

// Import generated code (uncomment after running codegen)
// import * as sui_gacha from './generated/sui_gacha/sui_gacha';

/**
 * Example: Configure SuiClient with package override
 * 
 * Replace YOUR_PACKAGE_ID with the actual package ID after deployment
 */
export function createSuiClient(network: 'devnet' | 'testnet' | 'mainnet' = 'testnet') {
    const rpcUrls = {
        devnet: 'https://fullnode.devnet.sui.io:443',
        testnet: 'https://fullnode.testnet.sui.io:443',
        mainnet: 'https://fullnode.mainnet.sui.io:443',
    };

    return new SuiClient({
        network,
        url: rpcUrls[network],
        mvr: {
            overrides: {
                packages: {
                    '@local-pkg/sui_gacha': 'YOUR_PACKAGE_ID', // Replace with actual package ID
                },
            },
        },
    });
}

/**
 * Example: Call a Move function using generated code
 * 
 * Uncomment and modify based on your actual Move module functions
 */
/*
export async function exampleMoveCall(
  client: SuiClient,
  signer: Ed25519Keypair
) {
  const tx = new Transaction();
  
  // Example: Call a function from your Move module
  // tx.add(sui_gacha.someFunction({
  //   arguments: {
  //     // Type-safe arguments based on your Move function signature
  //   },
  // }));

  const result = await client.signAndExecuteTransaction({
    transaction: tx,
    signer,
    options: {
      showEffects: true,
      showEvents: true,
    },
  });

  return result;
}
*/

/**
 * Example: Read data from Move module
 * 
 * Uncomment and modify based on your actual Move module
 */
/*
export async function exampleReadData(
  client: SuiClient,
  objectId: string
) {
  // Example: Read an object
  // const object = await client.getObject({
  //   id: objectId,
  //   options: {
  //     showContent: true,
  //     showType: true,
  //   },
  // });

  // return object;
}
*/

