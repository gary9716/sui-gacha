# Gacha System Design Document

## Table of Contents
1. [Overview](#overview)
2. [Core Concepts](#core-concepts)
3. [System Architecture](#system-architecture)
4. [Game Mechanics](#game-mechanics)
5. [Economy & Currency](#economy--currency)
6. [Item & Character Management](#item--character-management)
7. [User Experience Flows](#user-experience-flows)
8. [Technical Design](#technical-design)
9. [Security Considerations](#security-considerations)
10. [Future Enhancements](#future-enhancements)

## Overview

A gacha system is a monetization mechanic commonly used in mobile and blockchain games where players spend in-game currency or real money to obtain random items, characters, or equipment. The term "gacha" originates from Japanese gashapon (capsule toys) machines.

### Design Goals
- **Fairness**: Transparent probability rates and verifiable randomness
- **Engagement**: Balanced reward structure to maintain player interest
- **Monetization**: Sustainable revenue model through premium pulls
- **Transparency**: On-chain verifiability of all transactions and rates
- **Scalability**: Support for multiple banners, events, and item types

## Core Concepts

### 1. Pull/Summon
A single action where a player spends currency to receive one or more random items from a pool.

### 2. Banner/Gacha Pool
A curated collection of items available for pulling during a specific time period or event. Each banner has:
- Unique item pool
- Probability rates for each rarity tier
- Time-limited availability (optional)
- Featured items with boosted rates

### 3. Rarity Tiers
Items are categorized by rarity, typically:
- **Common** (1-2 stars): ~70-80% drop rate
- **Uncommon** (3 stars): ~15-20% drop rate
- **Rare** (4 stars): ~5-10% drop rate
- **Epic** (5 stars): ~1-3% drop rate
- **Legendary** (6 stars): ~0.1-1% drop rate

### 4. Pity System
A guarantee mechanism that ensures players receive high-rarity items after a certain number of unsuccessful pulls:
- **Soft Pity**: Gradually increasing rates after X pulls
- **Hard Pity**: Guaranteed high-rarity item at Y pulls
- **Pity Counter**: Tracks consecutive pulls without high-rarity items

## System Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────┐
│                    Gacha System                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Banner     │  │   Pull       │  │   Inventory  │ │
│  │  Manager     │  │   Engine     │  │   Manager    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Currency   │  │   Pity       │  │   Item       │ │
│  │   Manager    │  │   System     │  │   Registry   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Data Structures

#### Banner
- `banner_id`: Unique identifier
- `name`: Display name
- `description`: Banner description
- `start_time`: Banner start timestamp
- `end_time`: Banner end timestamp (optional)
- `item_pool`: List of available items with rates
- `featured_items`: Items with boosted rates
- `pity_config`: Pity system configuration

#### Pull Result
- `pull_id`: Unique pull identifier
- `banner_id`: Banner from which item was pulled
- `timestamp`: When the pull occurred
- `items`: List of items received
- `pity_counters`: Pity counter state after pull
- `random_seed`: Verifiable randomness source

#### Item
- `item_id`: Unique identifier
- `name`: Display name
- `rarity`: Rarity tier
- `item_type`: Character, Equipment, Material, etc.
- `metadata`: Additional properties (stats, abilities, etc.)
- `is_featured`: Whether item is featured in current banner

## Game Mechanics

### Pull Types

#### 1. Single Pull
- Cost: 1 pull currency unit
- Reward: 1 random item
- Use case: Quick pulls, testing rates

#### 2. Multi-Pull (10-Pull)
- Cost: 10 pull currency units (often with discount)
- Reward: 10 random items
- Guarantee: At least 1 item of specified rarity (e.g., 4-star+)
- Use case: Better value, guaranteed rewards

#### 3. Guaranteed Pull
- Cost: Premium currency
- Reward: Guaranteed high-rarity item
- Use case: Special events, first-time bonuses

### Probability System

#### Base Rates
Each banner defines base probability rates:
```
Common:     70%
Uncommon:   20%
Rare:        7%
Epic:        2.5%
Legendary:   0.5%
```

#### Featured Rate Boost
Featured items receive a rate boost:
- Featured Epic: 0.5% → 1.0% (doubled)
- Featured Legendary: 0.5% → 0.7% (40% boost)

#### Pity Mechanics

**Soft Pity (Epic/5-star)**
- Starts at pull 75
- Base rate: 2.5%
- Increases by 0.5% per pull after 75
- Max rate: 50% at pull 89

**Hard Pity (Epic/5-star)**
- Guaranteed at pull 90
- Resets pity counter

**Pity (Legendary/6-star)**
- Guaranteed at pull 300
- Independent counter from Epic pity

### Randomness Generation

For blockchain systems, use:
- **On-chain randomness**: Sui's random beacon or VRF
- **Commit-reveal scheme**: For fairness verification
- **Block hash + user seed**: Deterministic but unpredictable

## Economy & Currency

### Currency Types

#### 1. Free Currency
- **Source**: Daily login, quests, events
- **Usage**: Standard pulls
- **Accumulation**: Limited daily/weekly

#### 2. Premium Currency
- **Source**: Purchase, special events
- **Usage**: All pull types, guaranteed pulls
- **Conversion**: 1 premium = 1 pull

#### 3. Pull Tickets
- **Source**: Events, achievements
- **Usage**: Single pull equivalent
- **Stackable**: Can accumulate

### Pricing Model

```
Single Pull:     160 premium currency
10-Pull:        1600 premium currency (10% discount)
Guaranteed Pull: 3000 premium currency (special)
```

### Currency Flow

```
Player → Purchase/Quest → Currency Balance → Pull → Items
                                    ↓
                              Pity Counter Update
```

## Item & Character Management

### Item Categories

1. **Characters**
   - Unique heroes/units
   - Rarity determines base stats
   - Can be upgraded/evolved
   - Duplicates provide enhancement materials

2. **Equipment**
   - Weapons, armor, accessories
   - Rarity affects stat bonuses
   - Can be upgraded and refined

3. **Materials**
   - Enhancement materials
   - Evolution items
   - Crafting components

4. **Consumables**
   - Temporary buffs
   - Experience boosters
   - Currency packs

### Duplicate Handling

#### Option 1: Duplicate Conversion
- Duplicates convert to enhancement currency
- Rarity-based conversion rates:
  - Common: 1 point
  - Uncommon: 5 points
  - Rare: 20 points
  - Epic: 100 points
  - Legendary: 500 points

#### Option 2: Limit Break System
- Duplicates unlock additional potential
- Max limit break: 5-6 times
- Each break increases stats/abilities

#### Option 3: Constellation/Unlock System
- Duplicates unlock passive abilities
- Fixed number of unlocks per character
- Permanent character enhancement

## User Experience Flows

### Pull Flow

```
1. Player selects banner
2. Player chooses pull type (single/10-pull)
3. System checks currency balance
4. System deducts currency
5. System generates random result
6. System updates pity counters
7. System awards items to inventory
8. System displays pull animation
9. Player views results
10. System records transaction on-chain
```

### Banner Selection Flow

```
1. Player opens gacha menu
2. System displays active banners
3. Player views banner details:
   - Featured items
   - Rate information
   - Time remaining
   - Pity counter status
4. Player selects banner
5. Proceed to pull flow
```

### Inventory Management Flow

```
1. Player opens inventory
2. System displays items by category
3. Player can:
   - View item details
   - Filter by rarity/type
   - Sort by various criteria
   - Use/enhance items
   - Convert duplicates
```

## Technical Design

### On-Chain Storage (Sui Move)

#### Object Structure
```move
struct GachaBanner has key {
    id: UID,
    banner_id: ID,
    config: BannerConfig,
    active: bool,
    start_time: u64,
    end_time: Option<u64>,
}

struct PullResult has key {
    id: UID,
    pull_id: ID,
    player: address,
    banner_id: ID,
    items: vector<Item>,
    timestamp: u64,
    pity_counters: PityState,
}

struct PlayerPityState has key {
    id: UID,
    player: address,
    banner_id: ID,
    epic_pity: u64,
    legendary_pity: u64,
    last_pull_time: u64,
}
```

### Key Functions

#### Pull Function
```move
public fun pull(
    banner: &GachaBanner,
    currency: &mut Currency,
    player_pity: &mut PlayerPityState,
    ctx: &mut TxContext
): PullResult
```

#### Rate Calculation
```move
fun calculate_rates(
    base_rates: &Rates,
    pity_state: &PlayerPityState,
    pull_count: u64
): Rates
```

#### Random Item Selection
```move
fun select_item(
    item_pool: &vector<Item>,
    rates: &Rates,
    random_seed: u256
): Item
```

### Off-Chain Components

- **Frontend UI**: Pull interface, animations, inventory
- **Backend API**: Rate calculations, analytics, event management
- **Database**: Player data, pull history, analytics

## Security Considerations

### 1. Randomness Security
- Use verifiable random functions (VRF)
- Prevent manipulation of random seeds
- On-chain verification of randomness

### 2. Rate Transparency
- All rates stored on-chain
- Publicly verifiable probability calculations
- Historical pull data for verification

### 3. Anti-Exploit Measures
- Rate limiting on pulls
- Cooldown periods (optional)
- Maximum pulls per time period
- Duplicate prevention in single multi-pull

### 4. Economic Security
- Prevent currency duplication
- Secure currency transfers
- Audit trail for all transactions

### 5. Pity System Integrity
- Immutable pity counters
- On-chain storage of pity state
- Prevent counter manipulation

## Future Enhancements

### 1. Advanced Pity Systems
- Shared pity across banners
- Pity transfer between banners
- Pity inheritance for new banners

### 2. Event Systems
- Limited-time banners
- Double rate events
- Step-up banners (increasing rates)
- Guaranteed item milestones

### 3. Social Features
- Share pull results
- Leaderboards for rare pulls
- Guild/team gacha events

### 4. Trading & Marketplace
- Trade items with other players
- Marketplace for rare items
- Auction system for limited items

### 5. Advanced Mechanics
- Spark system (select item after X pulls)
- Wishlist system (prioritize certain items)
- Guaranteed featured item after Y pulls
- Multi-banner simultaneous pulls

### 6. Analytics & Insights
- Pull history dashboard
- Rate verification tools
- Pity calculator
- Expected value calculations

## Implementation Phases

### Phase 1: Core System
- Basic pull mechanism
- Single banner support
- Simple rarity system
- On-chain storage

### Phase 2: Pity System
- Pity counter implementation
- Soft and hard pity
- Pity state management

### Phase 3: Multi-Banner
- Banner management
- Multiple active banners
- Banner-specific pity

### Phase 4: Advanced Features
- Event system
- Trading capabilities
- Analytics dashboard

### Phase 5: Optimization
- Gas optimization
- Batch operations
- Caching strategies

## Conclusion

This design provides a comprehensive foundation for a gacha system that balances player engagement, fairness, and monetization. The on-chain nature of Sui allows for unprecedented transparency and verifiability, addressing common concerns with traditional gacha systems.

The modular design allows for incremental implementation and future enhancements while maintaining system integrity and security.

