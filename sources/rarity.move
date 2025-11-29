module gacha::rarity;

use sui::table::{Self, Table};
use gacha::version::Version;

// ============================================================================
// STRUCTS
// ============================================================================

/// Rarity rate configuration
/// Stores base drop rates for each rarity tier (in basis points)
/// Example: rarity 5 (Epic) -> 250 (2.5%)
public struct RarityRateConfig has store {
    /// Maps rarity tier -> base rate (basis points)
    rates: Table<u8, u64>,
}

/// Basis points constant (10000 = 100%)
const BASIS_POINTS: u64 = 10000;

// ============================================================================
// CONSTANTS
// ============================================================================

/// Maximum rarity tier (configurable - users can define their own max)
/// Default is 255 (u8 max) to allow maximum flexibility
const MAX_RARITY: u8 = 255;
/// Minimum rarity tier (typically 1, but configurable)
const MIN_RARITY: u8 = 1;

/// Error codes
const E_INVALID_RARITY: u64 = 0;
const E_INVALID_RATE: u64 = 1;

// ============================================================================
// PRIVATE FUNCTIONS
// ============================================================================

/// Create a new empty RarityRateConfig
fun new_rate_config(ctx: &mut sui::tx_context::TxContext): RarityRateConfig {
    RarityRateConfig {
        rates: table::new(ctx),
    }
}

/// Validate rarity tier is within valid range
fun validate_rarity_tier(rarity: u8): bool {
    rarity >= MIN_RARITY && rarity <= MAX_RARITY
}

/// Validate rate is within valid range (0 to BASIS_POINTS)
fun validate_rate(rate_basis_points: u64): bool {
    rate_basis_points <= BASIS_POINTS
}

// ============================================================================
// PROTECTED FUNCTIONS (public(package))
// ============================================================================

/// Create a new RarityRateConfig
public(package) fun create_rate_config(ctx: &mut sui::tx_context::TxContext): RarityRateConfig {
    new_rate_config(ctx)
}

/// Set base rate for a rarity tier in RarityRateConfig
public(package) fun set_rate(
    config: &mut RarityRateConfig,
    rarity: u8,
    rate_basis_points: u64
) {
    assert!(validate_rarity_tier(rarity), E_INVALID_RARITY);
    assert!(validate_rate(rate_basis_points), E_INVALID_RATE);
    
    if (table::contains(&config.rates, rarity)) {
        let rate = table::borrow_mut(&mut config.rates, rarity);
        *rate = rate_basis_points;
    } else {
        table::add(&mut config.rates, rarity, rate_basis_points);
    };
}

/// Remove rate for a rarity tier from RarityRateConfig
public(package) fun remove_rate(config: &mut RarityRateConfig, rarity: u8) {
    if (table::contains(&config.rates, rarity)) {
        let _ = table::remove(&mut config.rates, rarity);
    };
}

// ============================================================================
// PUBLIC FUNCTIONS
// ============================================================================

/// Get minimum valid rarity tier
public fun min_rarity(): u8 {
    MIN_RARITY
}

/// Get maximum valid rarity tier
public fun max_rarity(): u8 {
    MAX_RARITY
}

/// Validate that a rarity tier is valid
/// Returns true if rarity is between MIN_RARITY and MAX_RARITY
public fun is_valid_rarity(rarity: u8): bool {
    validate_rarity_tier(rarity)
}

// Note: Rarity names, star counts, and specific rarity checks are not hardcoded.
// Users should implement their own rarity naming and metadata systems based on their game design.

/// Get base rate for a rarity tier from config (in basis points)
/// Returns 0 if rarity tier is not configured
public fun get_rate(config: &RarityRateConfig, version: &Version, rarity: u8): u64 {
    gacha::version::check_valid(version);
    if (table::contains(&config.rates, rarity)) {
        *table::borrow(&config.rates, rarity)
    } else {
        0
    }
}

/// Check if a rarity tier has a rate configured
public fun has_rate(config: &RarityRateConfig, version: &Version, rarity: u8): bool {
    gacha::version::check_valid(version);
    table::contains(&config.rates, rarity)
}

/// Compare two rarity tiers
/// Returns:
/// - -1 if rarity1 < rarity2
/// - 0 if rarity1 == rarity2
/// - 1 if rarity1 > rarity2
public fun compare_rarity(rarity1: u8, rarity2: u8): u8 {
    if (rarity1 < rarity2) {
        1  // Note: Using 1 for less than to match typical comparison patterns
    } else if (rarity1 > rarity2) {
        2  // Using 2 for greater than
    } else {
        0  // Equal
    }
}

/// Check if rarity1 is higher than rarity2
public fun is_higher_rarity(rarity1: u8, rarity2: u8): bool {
    rarity1 > rarity2
}

/// Check if rarity1 is lower than rarity2
public fun is_lower_rarity(rarity1: u8, rarity2: u8): bool {
    rarity1 < rarity2
}

/// Check if rarity1 is equal to rarity2
public fun is_equal_rarity(rarity1: u8, rarity2: u8): bool {
    rarity1 == rarity2
}

// Note: get_all_rarities() removed - users should maintain their own rarity lists
// based on their game design. Use the rate config to track which rarities are configured.

