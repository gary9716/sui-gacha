# Application Developer Guide

This guide explains how to integrate and use the Sui Gacha framework in your web3 game or application. Whether you're building a full-featured gacha game or adding gacha mechanics to an existing game, this guide will help you get started.

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Core Concepts](#core-concepts)
4. [Integration Steps](#integration-steps)
5. [API Reference](#api-reference)
6. [Common Use Cases](#common-use-cases)
7. [TypeScript Integration](#typescript-integration)
8. [Best Practices](#best-practices)
9. [Examples](#examples)
10. [Troubleshooting](#troubleshooting)

## Overview

The Sui Gacha framework provides a complete on-chain gacha system for Sui blockchain applications. It includes:

- **Banner Management**: Create and manage time-limited banners with custom item pools
- **Pity System**: Player-specific, banner-specific pity counters with soft and hard pity
- **Item System**: Flexible item structure supporting characters, equipment, materials, and more
- **Player State**: Track player progress and pity counters across multiple banners
- **Version Management**: Built-in versioning for safe upgrades

### Key Features

- ✅ **On-Chain Transparency**: All rates, pity counters, and pull results are verifiable on-chain
- ✅ **Player-Specific Pity**: Each player has independent pity counters per banner
- ✅ **Flexible Configuration**: Customize rates, pity thresholds, and featured items per banner
- ✅ **TypeScript Support**: Auto-generated TypeScript bindings for type-safe integration
- ✅ **Security First**: Built with security best practices and version checking

## Getting Started

### Prerequisites

- Sui CLI installed ([Installation Guide](https://docs.sui.io/build/install))
- Node.js 20+ and npm/yarn
- Basic understanding of Sui Move and TypeScript

### Installation

1. **Add the package to your project:**

   If using the framework as a dependency in your Move project, add it to your `Move.toml`:

   ```toml
   [dependencies]
   Gacha = { git = "https://github.com/your-org/sui-gacha.git", subdir = ".", rev = "main" }
   ```

2. **Install TypeScript dependencies:**

   ```bash
   npm install @mysten/sui @mysten/codegen
   ```

3. **Generate TypeScript code:**

   ```bash
   make codegen
   # or
   npm run codegen
   ```

## Core Concepts

### 1. Banners

A **banner** is a time-limited event featuring specific items with boosted rates. Each banner has:

- Unique item pool
- Base drop rates for each rarity tier
- Featured items with boosted rates
- Pity system configuration
- Optional time limits

### 2. Items

**Items** are the rewards players receive from pulls. Each item has:

- Unique ID
- Name and description
- Rarity tier (1-6 stars)
- Item type (Character, Equipment, Material, Consumable)
- Flexible metadata for custom properties

### 3. Players

**Players** track player-specific state:

- Pity counters per banner
- Independent counters for each rarity tier
- Banner-specific progress

### 4. Pity System

The **pity system** ensures players eventually receive high-rarity items:

- **Soft Pity**: Gradually increasing rates after X pulls
- **Hard Pity**: Guaranteed item at Y pulls
- **Player-Specific**: Each player has independent counters
- **Banner-Specific**: Pity is tracked separately per banner

### 5. Version Management

All public functions require a `Version` object to ensure compatibility. The version object is shared on-chain and must be passed to all public API calls.

## Integration Steps

### Step 1: Deploy the Framework

1. **Clone or include the framework in your project**
2. **Build the Move package:**

   ```bash
   sui move build
   ```

3. **Publish to your network:**

   ```bash
   sui client publish --gas-budget 100000000
   ```

4. **Save the package ID** - you'll need it for TypeScript integration

### Step 2: Initialize Version Object

After publishing, the version object is automatically created and shared. You'll need to fetch it:

```typescript
// Fetch the shared Version object
const versionObject = await client.getObject({
  id: VERSION_OBJECT_ID, // From package publish output
  options: { showContent: true }
});
```

### Step 3: Create Your First Banner

In your Move module, create a banner:

```move
module mygame::gacha_manager;

use gacha::banner;
use gacha::item;
use sui::clock::Clock;

// Create a new banner
public fun create_character_banner(
    banner_id: ID,
    name: vector<u8>,
    description: vector<u8>,
    start_time: u64,
    end_time: u64,
    ctx: &mut TxContext
): Banner {
    let banner = banner::create(banner_id, name, description, start_time, end_time, ctx);
    
    // Configure base rates (in basis points: 250 = 2.5%)
    banner::configure_base_rate(&mut banner, 1, 7000); // 70% Common
    banner::configure_base_rate(&mut banner, 2, 2000); // 20% Uncommon
    banner::configure_base_rate(&mut banner, 3, 700);  // 7% Rare
    banner::configure_base_rate(&mut banner, 5, 250);  // 2.5% Epic
    banner::configure_base_rate(&mut banner, 6, 50);  // 0.5% Legendary
    
    // Configure pity system
    banner::configure_hard_pity(&mut banner, 5, 90, ctx);  // Epic guaranteed at 90
    banner::configure_soft_pity_start(&mut banner, 5, 75, ctx); // Soft pity starts at 75
    banner::configure_soft_pity_increase(&mut banner, 5, 50, ctx); // +0.5% per pull
    
    banner::configure_hard_pity(&mut banner, 6, 300, ctx); // Legendary guaranteed at 300
    
    banner
}
```

### Step 4: Create Items

Create items that will be in your banner:

```move
public fun create_character_item(
    item_id: ID,
    name: vector<u8>,
    rarity: u8,
    ctx: &mut TxContext
): Item {
    let item = item::create(item_id, name, rarity, item::ITEM_TYPE_CHARACTER, ctx);
    
    // Add custom metadata
    item::set_metadata_property(&mut item, b"attack", b"100");
    item::set_metadata_property(&mut item, b"defense", b"80");
    item::set_metadata_property(&mut item, b"element", b"fire");
    
    item
}
```

### Step 5: Add Items to Banner Pool

```move
public fun add_item_to_banner(
    banner: &mut Banner,
    item_id: ID
) {
    banner::add_item_to_pool(banner, item_id);
}
```

### Step 6: Create Player Object

When a player first interacts with your game:

```move
public fun create_player(ctx: &mut TxContext): Player {
    player::create(ctx)
}
```

### Step 7: Implement Pull Logic

The pull logic is typically implemented in your game module. Here's a conceptual example:

```move
public entry fun perform_pull(
    version: &Version,
    banner: &Banner,
    player: &mut Player,
    currency: &mut Coin<SUI>, // Your currency type
    clock: &Clock,
    ctx: &mut TxContext
) {
    // 1. Check banner is active
    let current_time = clock::timestamp_ms(clock);
    assert!(banner::is_active(banner, version, current_time), E_BANNER_INACTIVE);
    
    // 2. Check currency balance
    assert!(coin::value(currency) >= PULL_COST, E_INSUFFICIENT_FUNDS);
    
    // 3. Deduct currency
    let payment = coin::split(currency, PULL_COST, ctx);
    // Transfer to treasury...
    
    // 4. Calculate effective rates (with pity)
    let epic_pity = player::get_pity_for_banner(player, banner::get_banner_id(banner), 5);
    let effective_rate = calculate_effective_rate(banner, version, 5, epic_pity);
    
    // 5. Generate random result (using Sui's random module)
    let random_value = sui::random::random_u256(ctx);
    let rarity = determine_rarity(random_value, effective_rate);
    
    // 6. Select item from pool based on rarity
    let selected_item = select_item_from_pool(banner, rarity, ctx);
    
    // 7. Update pity counters
    if (item::get_rarity(&selected_item, version) >= 5) {
        player::reset_pity(player, banner::get_banner_id(banner), 5, ctx);
    } else {
        player::increment_pity(player, banner::get_banner_id(banner), 5, ctx);
    };
    
    // 8. Transfer item to player
    transfer::public_transfer(selected_item, tx_context::sender(ctx));
}
```

## API Reference

### Banner Module

#### Reading Banner Information

```move
// Get banner details
public fun get_banner_id(banner: &Banner): ID
public fun get_name(banner: &Banner): vector<u8>
public fun get_description(banner: &Banner): vector<u8>
public fun get_start_time(banner: &Banner): u64
public fun get_end_time(banner: &Banner): u64
public fun is_active(banner: &Banner, version: &Version, current_time: u64): bool

// Get rates
public fun get_base_rate(banner: &Banner, version: &Version, rarity: u8): u64
public fun get_featured_boost(banner: &Banner, version: &Version, item_id: ID): u64
public fun is_featured(banner: &Banner, version: &Version, item_id: ID): bool

// Get pity configuration
public fun get_hard_pity(banner: &Banner, version: &Version, rarity: u8): u64
public fun get_soft_pity_start(banner: &Banner, version: &Version, rarity: u8): u64
public fun get_soft_pity_increase(banner: &Banner, version: &Version, rarity: u8): u64
```

#### Configuring Banners (Package-level)

```move
// Create banner
public(package) fun create(...): Banner

// Manage item pool
public(package) fun add_item_to_pool(banner: &mut Banner, item_id: ID)
public(package) fun remove_item_from_pool(banner: &mut Banner, item_id: ID)
public(package) fun is_item_in_pool(banner: &Banner, item_id: ID): bool

// Configure rates and pity
public(package) fun configure_base_rate(banner: &mut Banner, rarity: u8, rate_basis_points: u64)
public(package) fun configure_featured_boost(banner: &mut Banner, item_id: ID, boost_basis_points: u64, ctx: &mut TxContext)
public(package) fun configure_hard_pity(banner: &mut Banner, rarity: u8, threshold: u64, ctx: &mut TxContext)
public(package) fun configure_soft_pity_start(banner: &mut Banner, rarity: u8, start: u64, ctx: &mut TxContext)
public(package) fun configure_soft_pity_increase(banner: &mut Banner, rarity: u8, increase_basis_points: u64, ctx: &mut TxContext)

// Control banner state
public(package) fun set_active(banner: &mut Banner, active: bool)
```

### Item Module

#### Reading Item Information

```move
public fun get_item_id(item: &Item, version: &Version): ID
public fun get_name(item: &Item, version: &Version): vector<u8>
public fun get_rarity(item: &Item, version: &Version): u8
public fun get_item_type_code(item: &Item, version: &Version): u8
public fun is_featured(item: &Item, version: &Version): bool
public fun get_metadata(item: &Item, version: &Version, key: vector<u8>): vector<u8>
public fun has_metadata(item: &Item, version: &Version, key: vector<u8>): bool

// Rarity helpers
public fun is_common(item: &Item, version: &Version): bool
public fun is_uncommon(item: &Item, version: &Version): bool
public fun is_rare(item: &Item, version: &Version): bool
public fun is_epic(item: &Item, version: &Version): bool
public fun is_legendary(item: &Item, version: &Version): bool
public fun get_rarity_name(item: &Item, version: &Version): vector<u8>

// Item type helpers
public fun is_character(item: &Item, version: &Version): bool
public fun is_equipment(item: &Item, version: &Version): bool
public fun is_material(item: &Item, version: &Version): bool
public fun is_consumable(item: &Item, version: &Version): bool
```

#### Creating Items (Package-level)

```move
public(package) fun create(
    item_id: ID,
    name: vector<u8>,
    rarity: u8,
    item_type_code: u8,
    ctx: &mut TxContext
): Item

public(package) fun set_featured(item: &mut Item, featured: bool)
public(package) fun set_metadata_property(item: &mut Item, key: vector<u8>, value: vector<u8>)
public(package) fun get_metadata_property(item: &Item, key: vector<u8>): vector<u8>
```

### Player Module

#### Reading Player State

```move
public fun create(ctx: &mut TxContext): Player
public fun get_pity_for_banner(player: &Player, banner_id: ID, rarity: u8): u64
public fun get_pity(state: &PityState, rarity: u8): u64
```

#### Managing Pity (Package-level)

```move
public(package) fun increment_pity(player: &mut Player, banner_id: ID, rarity: u8, ctx: &mut TxContext)
public(package) fun reset_pity(player: &mut Player, banner_id: ID, rarity: u8, ctx: &mut TxContext)
public(package) fun reset_pities(player: &mut Player, banner_id: ID, rarities: vector<u8>, ctx: &mut TxContext)
```

### Version Module

```move
public fun version(): u64
public fun check_valid(version: &Version)
```

## Common Use Cases

### Use Case 1: Display Active Banners

```typescript
async function getActiveBanners(client: SuiClient, version: Version) {
  // Query all Banner objects
  const banners = await client.getOwnedObjects({
    owner: BANNER_OWNER_ADDRESS,
    filter: { StructType: `${PACKAGE_ID}::banner::Banner` },
    options: { showContent: true }
  });

  const clock = await client.getLatestSuiSystemState();
  const currentTime = Date.now();

  return banners.filter(banner => {
    const content = banner.data?.content;
    if (!content || typeof content !== 'object') return false;
    
    const fields = content.fields as any;
    const startTime = Number(fields.start_time);
    const endTime = Number(fields.end_time);
    const active = fields.active;
    
    return active && 
           currentTime >= startTime && 
           (endTime === 0 || currentTime <= endTime);
  });
}
```

### Use Case 2: Display Player Pity Status

```typescript
async function getPlayerPityStatus(
  client: SuiClient,
  playerObjectId: string,
  bannerId: string
) {
  const player = await client.getObject({
    id: playerObjectId,
    options: { showContent: true }
  });

  // Get pity for Epic (rarity 5) and Legendary (rarity 6)
  const epicPity = await getPityForBanner(client, playerObjectId, bannerId, 5);
  const legendaryPity = await getPityForBanner(client, playerObjectId, bannerId, 6);

  return {
    epic: epicPity,
    legendary: legendaryPity
  };
}
```

### Use Case 3: Calculate Effective Rates

```typescript
function calculateEffectiveRate(
  baseRate: number,
  pityCount: number,
  softPityStart: number,
  softPityIncrease: number,
  hardPity: number
): number {
  // If at hard pity, rate is 100%
  if (pityCount >= hardPity) {
    return 10000; // 100% in basis points
  }

  // If in soft pity range, add bonus
  if (pityCount >= softPityStart) {
    const pullsPastSoftPity = pityCount - softPityStart;
    const bonus = pullsPastSoftPity * softPityIncrease;
    return Math.min(baseRate + bonus, 10000); // Cap at 100%
  }

  return baseRate;
}
```

### Use Case 4: Display Banner Rates

```typescript
async function getBannerRates(
  client: SuiClient,
  bannerObjectId: string,
  version: Version
) {
  const banner = await client.getObject({
    id: bannerObjectId,
    options: { showContent: true }
  });

  const rarities = [1, 2, 3, 5, 6]; // Common, Uncommon, Rare, Epic, Legendary
  
  const rates = await Promise.all(
    rarities.map(async (rarity) => {
      const baseRate = await getBaseRate(client, bannerObjectId, version, rarity);
      return {
        rarity,
        baseRate: baseRate / 100, // Convert from basis points to percentage
        name: getRarityName(rarity)
      };
    })
  );

  return rates;
}
```

## TypeScript Integration

### Setup

1. **Generate TypeScript code:**

   ```bash
   make codegen
   ```

2. **Configure SuiClient:**

   ```typescript
   import { SuiClient } from '@mysten/sui/client';

   const client = new SuiClient({
     network: 'testnet',
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

3. **Import generated code:**

   ```typescript
   import * as gacha from './generated/gacha/gacha';
   import { Transaction } from '@mysten/sui/transactions';
   ```

### Example: Reading Banner Data

```typescript
import { SuiClient } from '@mysten/sui/client';
import * as banner from './generated/gacha/banner';

async function getBannerInfo(
  client: SuiClient,
  bannerObjectId: string,
  versionObjectId: string
) {
  // Get banner object
  const bannerObj = await client.getObject({
    id: bannerObjectId,
    options: { showContent: true, showType: true }
  });

  // Get version object
  const versionObj = await client.getObject({
    id: versionObjectId,
    options: { showContent: true }
  });

  // Read banner properties using generated functions
  // Note: You'll need to call Move functions via transactions for some operations
  // For read-only operations, you can parse the object data directly

  const content = bannerObj.data?.content;
  if (content && typeof content === 'object' && 'fields' in content) {
    const fields = content.fields as any;
    return {
      bannerId: fields.banner_id,
      name: Buffer.from(fields.name, 'base64').toString('utf-8'),
      description: Buffer.from(fields.description, 'base64').toString('utf-8'),
      startTime: Number(fields.start_time),
      endTime: Number(fields.end_time),
      active: fields.active
    };
  }
}
```

### Example: Creating a Pull Transaction

```typescript
import { Transaction } from '@mysten/sui/transactions';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import * as mygame from './generated/mygame/gacha_manager';

async function performPull(
  client: SuiClient,
  signer: Ed25519Keypair,
  bannerObjectId: string,
  playerObjectId: string,
  versionObjectId: string,
  currencyObjectId: string
) {
  const tx = new Transaction();

  // Call your game's pull function
  tx.moveCall({
    target: `${PACKAGE_ID}::gacha_manager::perform_pull`,
    arguments: [
      versionObjectId,
      bannerObjectId,
      playerObjectId,
      currencyObjectId,
      // ... other arguments
    ],
    typeArguments: []
  });

  const result = await client.signAndExecuteTransaction({
    transaction: tx,
    signer,
    options: {
      showEffects: true,
      showEvents: true,
      showObjectChanges: true
    }
  });

  return result;
}
```

## Best Practices

### 1. Version Management

- **Always pass Version object**: All public functions require a version parameter
- **Check version compatibility**: Verify version matches before calling functions
- **Handle version mismatches**: Show user-friendly errors when versions don't match

### 2. Error Handling

```typescript
try {
  const result = await performPull(...);
} catch (error) {
  if (error.message.includes('E_VERSION_INVALID')) {
    // Handle version mismatch
    console.error('Please update your client to the latest version');
  } else if (error.message.includes('E_BANNER_INACTIVE')) {
    // Handle inactive banner
    console.error('This banner is no longer active');
  }
  // ... handle other errors
}
```

### 3. Pity Counter Display

- **Show current pity**: Display current pity count (e.g., "Epic Pity: 45/90")
- **Show effective rates**: Calculate and display current effective rates with soft pity
- **Show pulls until guarantee**: Display "X pulls until guaranteed Epic"

### 4. Banner Management

- **Validate banner state**: Always check if banner is active before allowing pulls
- **Check time limits**: Verify current time is within banner's active period
- **Handle expired banners**: Gracefully handle banners that have ended

### 5. Item Pool Management

- **Validate items**: Ensure items exist and are in the pool before adding to banner
- **Featured items**: Mark featured items and apply boost multipliers
- **Pool size**: Consider pool size when calculating selection probabilities

### 6. Security

- **Input validation**: Validate all inputs on both client and server side
- **Access control**: Ensure only authorized users can perform pulls
- **Currency checks**: Verify sufficient currency before processing pulls
- **Rate limiting**: Implement rate limiting to prevent abuse

### 7. User Experience

- **Loading states**: Show loading indicators during pull transactions
- **Transaction feedback**: Display transaction status and results clearly
- **Pity visibility**: Make pity counters easily visible to build trust
- **Rate transparency**: Display all rates clearly to players

## Examples

### Complete Example: Simple Gacha Game

See the [example.ts](src/example.ts) file for a complete working example.

### Example: Multi-Banner System

```move
module mygame::multi_banner;

use gacha::banner;
use gacha::player;

// Store multiple banners
public struct GameState has key {
    id: UID,
    banners: Table<ID, Banner>,
}

public fun create_game_state(ctx: &mut TxContext): GameState {
    GameState {
        id: object::new(ctx),
        banners: table::new(ctx),
    }
}

public fun add_banner(
    game: &mut GameState,
    banner_id: ID,
    banner: Banner
) {
    table::add(&mut game.banners, banner_id, banner);
}

public fun get_banner(game: &GameState, banner_id: ID): &Banner {
    table::borrow(&game.banners, banner_id)
}
```

### Example: Event Banner with Time Limit

```move
public fun create_event_banner(
    event_name: vector<u8>,
    duration_days: u64,
    ctx: &mut TxContext
): Banner {
    let clock = clock::timestamp_ms(clock::Clock::dummy());
    let start_time = clock;
    let end_time = start_time + (duration_days * 24 * 60 * 60 * 1000);
    
    let banner = banner::create(
        sui::object::id_from_address(@0x123), // Generate unique ID
        event_name,
        b"Limited time event banner",
        start_time,
        end_time,
        ctx
    );
    
    // Configure event-specific rates
    banner::configure_base_rate(&mut banner, 5, 500); // 5% Epic for event
    banner::configure_base_rate(&mut banner, 6, 100); // 1% Legendary for event
    
    banner
}
```

## Troubleshooting

### Issue: Version Mismatch Error

**Problem**: Getting `E_VERSION_INVALID` errors

**Solution**:
1. Fetch the latest version object from chain
2. Ensure your client code matches the deployed package version
3. Update your client if package was upgraded

### Issue: Banner Not Active

**Problem**: Banner shows as inactive even though it should be active

**Solution**:
1. Check `start_time` and `end_time` values
2. Verify `active` flag is set to `true`
3. Ensure current time is within the time range
4. Check if banner was manually deactivated

### Issue: Pity Counter Not Updating

**Problem**: Pity counter doesn't increment after pulls

**Solution**:
1. Verify you're calling `increment_pity` in your pull function
2. Check that you're using the correct banner_id
3. Ensure player object is mutable in your function
4. Verify transaction succeeded

### Issue: Item Not in Pool

**Problem**: Getting `E_ITEM_NOT_IN_POOL` error

**Solution**:
1. Add item to banner pool before setting it as featured
2. Verify item_id matches exactly
3. Check that item exists before adding to pool

### Issue: TypeScript Code Generation Fails

**Problem**: `make codegen` fails with errors

**Solution**:
1. Ensure Move package builds successfully: `sui move build`
2. Clean and rebuild: `make clean && make build`
3. Check `sui-codegen.config.ts` configuration
4. Verify package ID in config matches deployed package

## Additional Resources

- [Sui Move Documentation](https://docs.sui.io/build/move)
- [Sui TypeScript SDK](https://docs.sui.io/build/typescript-sdk)
- [Framework Design Document](DESIGN.md)
- [TypeScript Code Generation Guide](CODEGEN.md)
- [Project README](README.md)

## Support

For issues, questions, or contributions:

1. Check existing documentation
2. Review code examples
3. Open an issue on GitHub
4. Contact the maintainers

---

**Happy Building!** 🎮✨

