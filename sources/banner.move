module gacha::banner;

use sui::table::{Self, Table};
use gacha::version::Version;
use std::string::String;

// ============================================================================
// STRUCTS
// ============================================================================

/// Pity configuration for a banner
/// Defines soft pity and hard pity thresholds for each rarity tier
public struct PityConfig has store {
    /// Maps rarity tier -> hard pity threshold (guaranteed at this count)
    /// Example: rarity 5 (Epic) -> 90 pulls
    hard_pity: Table<u8, u64>,
    /// Maps rarity tier -> soft pity start (when rates start increasing)
    /// Example: rarity 5 (Epic) -> 75 pulls
    soft_pity_start: Table<u8, u64>,
    /// Maps rarity tier -> soft pity rate increase per pull
    /// Example: rarity 5 (Epic) -> 0.5% increase per pull
    soft_pity_increase: Table<u8, u64>,
}

/// Banner configuration
/// Stores all the settings for a gacha banner
public struct BannerConfig has store {
    /// Base drop rates for each rarity tier (in basis points, e.g., 250 = 2.5%)
    /// Maps rarity tier -> base rate (basis points)
    base_rates: Table<u8, u64>,
    /// Featured items with boosted rates
    /// Maps item_id -> boost multiplier (in basis points, e.g., 200 = 2x)
    featured_boosts: Table<ID, u64>,
    /// Pity system configuration
    pity_config: PityConfig,
}

/// Banner struct representing a gacha banner
/// Each banner has its own item pool, rates, and configuration
public struct Banner has key {
    id: UID,
    /// Unique banner identifier
    banner_id: ID,
    /// Display name
    name: String,
    /// Banner description
    description: String,
    /// Banner start timestamp
    start_time: u64,
    /// Banner end timestamp (0 means no end time)
    end_time: u64,
    /// Whether the banner is currently active
    active: bool,
    /// Banner configuration (rates, pity, etc.)
    config: BannerConfig,
    /// Maps item_id -> whether item is in the pool
    item_pool: Table<ID, bool>,
}

// ============================================================================
// CONSTANTS
// ============================================================================

/// Error codes
const E_INVALID_TIME_RANGE: u64 = 0;
const E_ITEM_NOT_IN_POOL: u64 = 1;
const E_INVALID_RATE: u64 = 2;

/// Basis points constant (10000 = 100%)
const BASIS_POINTS: u64 = 10000;

// ============================================================================
// PRIVATE FUNCTIONS
// ============================================================================

/// Create a new empty PityConfig
fun new_pity_config(ctx: &mut sui::tx_context::TxContext): PityConfig {
    PityConfig {
        hard_pity: table::new(ctx),
        soft_pity_start: table::new(ctx),
        soft_pity_increase: table::new(ctx),
    }
}

/// Create a new empty BannerConfig
fun new_banner_config(ctx: &mut sui::tx_context::TxContext): BannerConfig {
    BannerConfig {
        base_rates: table::new(ctx),
        featured_boosts: table::new(ctx),
        pity_config: new_pity_config(ctx),
    }
}

/// Set base rate for a rarity tier in BannerConfig
fun set_base_rate(config: &mut BannerConfig, rarity: u8, rate_basis_points: u64) {
    assert!(rate_basis_points <= BASIS_POINTS, E_INVALID_RATE);
    if (table::contains(&config.base_rates, rarity)) {
        let rate = table::borrow_mut(&mut config.base_rates, rarity);
        *rate = rate_basis_points;
    } else {
        table::add(&mut config.base_rates, rarity, rate_basis_points);
    };
}

/// Set featured boost for an item in BannerConfig
fun set_featured_boost(config: &mut BannerConfig, item_id: ID, boost_multiplier_basis_points: u64, _ctx: &mut sui::tx_context::TxContext) {
    if (table::contains(&config.featured_boosts, item_id)) {
        let boost = table::borrow_mut(&mut config.featured_boosts, item_id);
        *boost = boost_multiplier_basis_points;
    } else {
        table::add(&mut config.featured_boosts, item_id, boost_multiplier_basis_points);
    };
}

/// Set hard pity threshold for a rarity tier
fun set_hard_pity(config: &mut BannerConfig, rarity: u8, threshold: u64, _ctx: &mut sui::tx_context::TxContext) {
    let pity_config = &mut config.pity_config;
    if (table::contains(&pity_config.hard_pity, rarity)) {
        let threshold_ref = table::borrow_mut(&mut pity_config.hard_pity, rarity);
        *threshold_ref = threshold;
    } else {
        table::add(&mut pity_config.hard_pity, rarity, threshold);
    };
}

/// Set soft pity start for a rarity tier
fun set_soft_pity_start(config: &mut BannerConfig, rarity: u8, start: u64, _ctx: &mut sui::tx_context::TxContext) {
    let pity_config = &mut config.pity_config;
    if (table::contains(&pity_config.soft_pity_start, rarity)) {
        let start_ref = table::borrow_mut(&mut pity_config.soft_pity_start, rarity);
        *start_ref = start;
    } else {
        table::add(&mut pity_config.soft_pity_start, rarity, start);
    };
}

/// Set soft pity rate increase for a rarity tier
fun set_soft_pity_increase(config: &mut BannerConfig, rarity: u8, increase_basis_points: u64, _ctx: &mut sui::tx_context::TxContext) {
    let pity_config = &mut config.pity_config;
    if (table::contains(&pity_config.soft_pity_increase, rarity)) {
        let increase_ref = table::borrow_mut(&mut pity_config.soft_pity_increase, rarity);
        *increase_ref = increase_basis_points;
    } else {
        table::add(&mut pity_config.soft_pity_increase, rarity, increase_basis_points);
    };
}

/// Check if banner is currently active based on time
fun is_banner_active_by_time(banner: &Banner, current_time: u64): bool {
    if (!banner.active) {
        return false
    };
    if (current_time < banner.start_time) {
        return false
    };
    if (banner.end_time > 0 && current_time > banner.end_time) {
        return false
    };
    true
}

// ============================================================================
// PROTECTED FUNCTIONS (public(package))
// ============================================================================

/// Create a new banner with configuration
/// This is a package-level function for internal use
public(package) fun create(
    banner_id: ID,
    name: String,
    description: String,
    start_time: u64,
    end_time: u64,
    ctx: &mut sui::tx_context::TxContext
): Banner {
    assert!(end_time == 0 || end_time > start_time, E_INVALID_TIME_RANGE);
    
    Banner {
        id: sui::object::new(ctx),
        banner_id,
        name,
        description,
        start_time,
        end_time,
        active: true,
        config: new_banner_config(ctx),
        item_pool: table::new(ctx),
    }
}

/// Add an item to the banner's item pool
public(package) fun add_item_to_pool(banner: &mut Banner, item_id: ID) {
    if (!table::contains(&banner.item_pool, item_id)) {
        table::add(&mut banner.item_pool, item_id, true);
    };
}

/// Remove an item from the banner's item pool
public(package) fun remove_item_from_pool(banner: &mut Banner, item_id: ID) {
    if (table::contains(&banner.item_pool, item_id)) {
        let _ = table::remove(&mut banner.item_pool, item_id);
    };
}

/// Check if an item is in the banner's pool
public(package) fun is_item_in_pool(banner: &Banner, item_id: ID): bool {
    table::contains(&banner.item_pool, item_id)
}

/// Configure base rate for a rarity tier
public(package) fun configure_base_rate(banner: &mut Banner, rarity: u8, rate_basis_points: u64) {
    set_base_rate(&mut banner.config, rarity, rate_basis_points);
}

/// Configure featured boost for an item
public(package) fun configure_featured_boost(
    banner: &mut Banner,
    item_id: ID,
    boost_multiplier_basis_points: u64,
    ctx: &mut sui::tx_context::TxContext
) {
    assert!(is_item_in_pool(banner, item_id), E_ITEM_NOT_IN_POOL);
    set_featured_boost(&mut banner.config, item_id, boost_multiplier_basis_points, ctx);
}

/// Configure hard pity threshold for a rarity tier
public(package) fun configure_hard_pity(
    banner: &mut Banner,
    rarity: u8,
    threshold: u64,
    ctx: &mut sui::tx_context::TxContext
) {
    set_hard_pity(&mut banner.config, rarity, threshold, ctx);
}

/// Configure soft pity start for a rarity tier
public(package) fun configure_soft_pity_start(
    banner: &mut Banner,
    rarity: u8,
    start: u64,
    ctx: &mut sui::tx_context::TxContext
) {
    set_soft_pity_start(&mut banner.config, rarity, start, ctx);
}

/// Configure soft pity rate increase for a rarity tier
public(package) fun configure_soft_pity_increase(
    banner: &mut Banner,
    rarity: u8,
    increase_basis_points: u64,
    ctx: &mut sui::tx_context::TxContext
) {
    set_soft_pity_increase(&mut banner.config, rarity, increase_basis_points, ctx);
}

/// Set banner active status
public(package) fun set_active(banner: &mut Banner, active: bool) {
    banner.active = active;
}

// ============================================================================
// PUBLIC FUNCTIONS
// ============================================================================

/// Get banner ID
public fun get_banner_id(banner: &Banner): ID {
    banner.banner_id
}

/// Get banner name
public fun get_name(banner: &Banner): String {
    banner.name
}

/// Get banner description
public fun get_description(banner: &Banner): String {
    banner.description
}

/// Get banner start time
public fun get_start_time(banner: &Banner): u64 {
    banner.start_time
}

/// Get banner end time (0 means no end time)
public fun get_end_time(banner: &Banner): u64 {
    banner.end_time
}

/// Check if banner is active
public fun is_active(banner: &Banner, version: &Version, current_time: u64): bool {
    gacha::version::check_valid(version);
    is_banner_active_by_time(banner, current_time)
}

/// Get base rate for a rarity tier (in basis points)
/// Returns 0 if rarity tier is not configured
public fun get_base_rate(banner: &Banner, version: &Version, rarity: u8): u64 {
    gacha::version::check_valid(version);
    if (table::contains(&banner.config.base_rates, rarity)) {
        *table::borrow(&banner.config.base_rates, rarity)
    } else {
        0
    }
}

/// Get featured boost for an item (in basis points, e.g., 200 = 2x)
/// Returns 0 if item is not featured
public fun get_featured_boost(banner: &Banner, version: &Version, item_id: ID): u64 {
    gacha::version::check_valid(version);
    if (table::contains(&banner.config.featured_boosts, item_id)) {
        *table::borrow(&banner.config.featured_boosts, item_id)
    } else {
        0
    }
}

/// Get hard pity threshold for a rarity tier
/// Returns 0 if not configured
public fun get_hard_pity(banner: &Banner, version: &Version, rarity: u8): u64 {
    gacha::version::check_valid(version);
    let pity_config = &banner.config.pity_config;
    if (table::contains(&pity_config.hard_pity, rarity)) {
        *table::borrow(&pity_config.hard_pity, rarity)
    } else {
        0
    }
}

/// Get soft pity start for a rarity tier
/// Returns 0 if not configured
public fun get_soft_pity_start(banner: &Banner, version: &Version, rarity: u8): u64 {
    gacha::version::check_valid(version);
    let pity_config = &banner.config.pity_config;
    if (table::contains(&pity_config.soft_pity_start, rarity)) {
        *table::borrow(&pity_config.soft_pity_start, rarity)
    } else {
        0
    }
}

/// Get soft pity rate increase for a rarity tier (in basis points)
/// Returns 0 if not configured
public fun get_soft_pity_increase(banner: &Banner, version: &Version, rarity: u8): u64 {
    gacha::version::check_valid(version);
    let pity_config = &banner.config.pity_config;
    if (table::contains(&pity_config.soft_pity_increase, rarity)) {
        *table::borrow(&pity_config.soft_pity_increase, rarity)
    } else {
        0
    }
}

/// Check if an item is featured in the banner
public fun is_featured(banner: &Banner, version: &Version, item_id: ID): bool {
    gacha::version::check_valid(version);
    table::contains(&banner.config.featured_boosts, item_id)
}

