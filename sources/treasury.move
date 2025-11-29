module gacha::treasury;

use sui::coin::{Self, Coin};
use sui::balance::{Self, Balance};
use gacha::version::Version;
use gacha::admin::{AdminCap, AdminRegistry};

// ============================================================================
// STRUCTS
// ============================================================================

/// Treasury for storing currency received from players
/// Generic over coin type T - each treasury stores one currency type
/// Create multiple treasuries for different currency types if needed
/// Should be shared as a shared object to use with AdminRegistry
public struct Treasury<phantom T> has key {
    id: UID,
    /// Balance of currency stored in treasury
    balance: Balance<T>,
}

// ============================================================================
// CONSTANTS
// ============================================================================

/// Error codes
const E_INSUFFICIENT_BALANCE: u64 = 0;
const E_INVALID_AMOUNT: u64 = 1;

// ============================================================================
// PROTECTED FUNCTIONS (public(package))
// ============================================================================

/// Create a new treasury with zero balance
/// Treasury should be shared as a shared object to use with AdminRegistry
public(package) fun create<T>(ctx: &mut sui::tx_context::TxContext): Treasury<T> {
    Treasury {
        id: sui::object::new(ctx),
        balance: balance::zero(),
    }
}

/// Deposit coins into treasury (package-level for internal use)
/// This is the main deposit function used by pull operations
public(package) fun deposit<T>(
    treasury: &mut Treasury<T>,
    payment: Coin<T>
) {
    balance::join(&mut treasury.balance, coin::into_balance(payment));
}

/// Withdraw coins from treasury (package-level, requires admin)
/// Verifies admin authorization through AdminCap and AdminRegistry
public(package) fun withdraw<T>(
    treasury: &mut Treasury<T>,
    admin_cap: &AdminCap,
    registry: &AdminRegistry,
    amount: u64,
    version: &Version,
    ctx: &mut sui::tx_context::TxContext
): Coin<T> {
    // Verify AdminCap is valid and eligible for this treasury shared object
    let treasury_id = sui::object::id(treasury);
    gacha::admin::verify_admin_cap(admin_cap, registry, treasury_id, version);
    
    let balance_value = balance::value(&treasury.balance);
    assert!(balance_value >= amount, E_INSUFFICIENT_BALANCE);
    assert!(amount > 0, E_INVALID_AMOUNT);
    
    let split_balance = balance::split(&mut treasury.balance, amount);
    coin::from_balance(split_balance, ctx)
}

// ============================================================================
// PUBLIC FUNCTIONS
// ============================================================================

/// Get balance in treasury (in base units)
public fun get_balance<T>(treasury: &Treasury<T>, version: &Version): u64 {
    gacha::version::check_valid(version);
    balance::value(&treasury.balance)
}

// ============================================================================
// ENTRY FUNCTIONS
// ============================================================================

/// Entry function to deposit coins into treasury
/// Players can call this directly to deposit currency
entry fun deposit_entry<T>(
    treasury: &mut Treasury<T>,
    payment: Coin<T>,
    version: &Version
) {
    gacha::version::check_valid(version);
    deposit(treasury, payment);
}

/// Entry function to withdraw coins from treasury (admin only)
/// Requires AdminCap that is eligible for this treasury shared object
/// Note: Entry functions cannot return values, so this transfers the coin to the caller
entry fun withdraw_entry<T>(
    treasury: &mut Treasury<T>,
    admin_cap: &AdminCap,
    registry: &AdminRegistry,
    amount: u64,
    version: &Version,
    ctx: &mut sui::tx_context::TxContext
) {
    gacha::version::check_valid(version);
    let coin = withdraw(treasury, admin_cap, registry, amount, version, ctx);
    sui::transfer::public_transfer(coin, sui::tx_context::sender(ctx));
}

