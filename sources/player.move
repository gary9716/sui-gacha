module gacha::player;

use sui::table::{Self, Table};

/// Pity state for a specific banner
/// 
/// Pity counters ensure players eventually receive high-rarity items even with bad luck.
/// They track consecutive pulls without receiving items of specific rarity tiers.
/// 
/// Uses a Table to map rarity tier (u8) -> pity counter (u64), allowing support for
/// any number of rarity tiers dynamically.
public struct PityState has store {
    /// Maps rarity tier to pity counter
    /// Key: rarity tier (e.g., 5 for Epic, 6 for Legendary)
    /// Value: number of consecutive pulls without receiving that rarity tier
    counters: Table<u8, u64>,
}

/// Player struct that stores pity counters for each banner
public struct Player has key {
    id: UID,
    /// Maps banner_id -> PityState for each banner
    pity_states: Table<ID, PityState>,
}

//private functions
/// Create a new empty PityState
fun new_pity_state(ctx: &mut sui::tx_context::TxContext): PityState {
    PityState {
        counters: table::new(ctx),
    }
}

/// Set pity counter for a specific rarity tier
fun set_pity(state: &mut PityState, rarity: u8, count: u64) {
    if (!table::contains(&state.counters, rarity)) {
        table::add(&mut state.counters, rarity, count);
        return
    };
    
    let pity = table::borrow_mut(&mut state.counters, rarity);
    *pity = count;
}

/// Get pity state for a specific banner
/// Returns a mutable reference to the PityState, or creates a new one if it doesn't exist
fun get_or_create_pity_state(player: &mut Player, banner_id: ID, ctx: &mut sui::tx_context::TxContext): &mut PityState {
    if (!table::contains(&player.pity_states, banner_id)) {
        let new_state = new_pity_state(ctx);
        table::add(&mut player.pity_states, banner_id, new_state);
    };
    table::borrow_mut(&mut player.pity_states, banner_id)
}

//protected functions
/// Increment pity counter for a specific rarity tier on a banner
public(package) fun increment_pity(
    player: &mut Player,
    banner_id: sui::object::ID,
    rarity: u8,
    ctx: &mut sui::tx_context::TxContext
) {
    let state = get_or_create_pity_state(player, banner_id, ctx);
    let current = get_pity(state, rarity);
    set_pity(state, rarity, current + 1);
}

/// Reset pity counter for a specific rarity tier on a banner
/// Called when an item of that rarity tier is pulled
public(package) fun reset_pity(
    player: &mut Player,
    banner_id: sui::object::ID,
    rarity: u8,
    ctx: &mut sui::tx_context::TxContext
) {
    let state = get_or_create_pity_state(player, banner_id, ctx);
    set_pity(state, rarity, 0);
}

/// Reset pity counters for specified rarities on a banner
/// Since Table doesn't have drop, we can't remove and recreate the state
/// This function resets the specified rarities to 0
public(package) fun reset_pities(
    player: &mut Player,
    banner_id: ID,
    rarities: vector<u8>,
    ctx: &mut sui::tx_context::TxContext
) {
    let state = get_or_create_pity_state(player, banner_id, ctx);
    let mut i = 0;
    let len = vector::length(&rarities);
    while (i < len) {
        let rarity = *vector::borrow(&rarities, i);
        set_pity(state, rarity, 0);
        i = i + 1;
    };
}

//public functions
/// Get pity counter for a specific rarity tier
/// Returns 0 if the rarity tier doesn't have a counter yet
public fun get_pity(state: &PityState, rarity: u8): u64 {
    if (table::contains(&state.counters, rarity)) {
        *table::borrow(&state.counters, rarity)
    } else {
        0
    }
}

/// Create a new Player object
public fun create(ctx: &mut sui::tx_context::TxContext): Player {
    Player {
        id: sui::object::new(ctx),
        pity_states: table::new(ctx),
    }
}

/// Get pity counter for a specific rarity tier on a banner
/// Returns 0 if the banner or rarity tier doesn't have a counter yet
public fun get_pity_for_banner(player: &Player, banner_id: sui::object::ID, rarity: u8): u64 {
    if (table::contains(&player.pity_states, banner_id)) {
        let state = table::borrow(&player.pity_states, banner_id);
        get_pity(state, rarity)
    } else {
        0
    }
}
