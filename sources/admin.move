module gacha::admin;

use sui::table::{Self, Table};
use gacha::version::Version;

// ============================================================================
// STRUCTS
// ============================================================================

// OTW (One Time Witness) for publisher verification and init
public struct ADMIN has drop {}

/// Admin capability - soul-bound NFT that grants admin rights for a specific shared object
/// Only has 'key' ability, making it non-transferable (soul-bound)
public struct AdminCap has key {
    id: UID,
    /// The shared object ID this AdminCap is for
    for_object: ID,
}

/// Admin registry that tracks which AdminCaps are eligible
/// Maps AdminCap object ID -> bool (eligible or not)
public struct AdminRegistry has key {
    id: UID,
    /// Maps AdminCap object ID -> bool (eligible or not)
    /// Example: admin_cap_id_1 -> true, admin_cap_id_2 -> false
    /// Only AdminCaps with value true are considered eligible for admin operations
    eligible_admins: Table<ID, bool>,
}

// ============================================================================
// CONSTANTS
// ============================================================================

/// Error codes
const E_ADMIN_NOT_ELIGIBLE: u64 = 0;
const E_WRONG_OBJECT: u64 = 1;

// ============================================================================
// PRIVATE FUNCTIONS
// ============================================================================

/// Initialize AdminRegistry - only called automatically on package publish
/// Creates and shares the AdminRegistry on-chain
/// Creates an AdminCap for the publisher for the AdminRegistry shared object itself
fun init(otw: ADMIN, ctx: &mut sui::tx_context::TxContext) {
    sui::package::claim_and_keep(otw, ctx);
    let mut registry = AdminRegistry {
        id: sui::object::new(ctx),
        eligible_admins: table::new(ctx),
    };
    
    // Create AdminCap for publisher for AdminRegistry shared object (itself)
    let registry_id = sui::object::id(&registry);
    let publisher_admin_cap = AdminCap {
        id: sui::object::new(ctx),
        for_object: registry_id,
    };
    
    // Mark AdminCap as eligible
    let admin_cap_id = sui::object::id(&publisher_admin_cap);
    table::add(&mut registry.eligible_admins, admin_cap_id, true);
    
    // Transfer AdminCap to publisher
    sui::transfer::transfer(publisher_admin_cap, ctx.sender());
    
    // Share the AdminRegistry so it can be accessed by all
    sui::transfer::share_object(registry);
}

/// Check if an AdminCap is eligible
fun is_admin_eligible(registry: &AdminRegistry, admin_cap_id: ID): bool {
    if (table::contains(&registry.eligible_admins, admin_cap_id)) {
        *table::borrow(&registry.eligible_admins, admin_cap_id)
    } else {
        false
    }
}

/// Create a new AdminCap for a shared object
/// Private function - only callable within this module
fun create_admin_cap(
    for_object: ID,
    ctx: &mut sui::tx_context::TxContext
): AdminCap {
    AdminCap {
        id: sui::object::new(ctx),
        for_object,
    }
}

/// Mark an AdminCap as eligible
/// Private function - only callable within this module
fun mark_admin_eligible(
    registry: &mut AdminRegistry,
    admin_cap_id: ID
) {
    if (table::contains(&registry.eligible_admins, admin_cap_id)) {
        let eligible = table::borrow_mut(&mut registry.eligible_admins, admin_cap_id);
        *eligible = true;
    } else {
        table::add(&mut registry.eligible_admins, admin_cap_id, true);
    };
}

/// Mark an AdminCap as not eligible
/// Private function - only callable within this module
fun mark_admin_not_eligible(
    registry: &mut AdminRegistry,
    admin_cap_id: ID
) {
    if (table::contains(&registry.eligible_admins, admin_cap_id)) {
        let eligible = table::borrow_mut(&mut registry.eligible_admins, admin_cap_id);
        *eligible = false;
    } else {
        table::add(&mut registry.eligible_admins, admin_cap_id, false);
    };
}

/// Create and register an AdminCap for a shared object
/// Requires an AdminCap for the AdminRegistry shared object itself for authorization
/// Private function - only callable within this module
fun create_and_register_admin_cap(
    admin_cap: &AdminCap,
    registry: &mut AdminRegistry,
    for_object: ID,
    ctx: &mut sui::tx_context::TxContext
): AdminCap {
    // Verify admin_cap is authorized for the AdminRegistry shared object itself
    let registry_id = sui::object::id(registry);
    assert!(admin_cap.for_object == registry_id, E_WRONG_OBJECT);
    let admin_cap_id = sui::object::id(admin_cap);
    assert!(is_admin_eligible(registry, admin_cap_id), E_ADMIN_NOT_ELIGIBLE);
    
    let new_admin_cap = create_admin_cap(for_object, ctx);
    let new_admin_cap_id = sui::object::id(&new_admin_cap);
    mark_admin_eligible(registry, new_admin_cap_id);
    new_admin_cap
}

// ============================================================================
// PROTECTED FUNCTIONS (public(package))
// ============================================================================

/// Create an AdminCap for a shared object (package-level)
/// AdminCap must be registered via entry function to be eligible
public(package) fun create_admin_cap_package(
    for_object: ID,
    ctx: &mut sui::tx_context::TxContext
): AdminCap {
    create_admin_cap(for_object, ctx)
}

// ============================================================================
// PUBLIC FUNCTIONS
// ============================================================================

/// Get the shared object ID that an AdminCap is for
public fun get_admin_cap_for_object(admin_cap: &AdminCap, version: &Version): ID {
    gacha::version::check_valid(version);
    admin_cap.for_object
}

/// Check if an AdminCap is eligible
public fun is_admin_cap_eligible(
    registry: &AdminRegistry,
    admin_cap: &AdminCap,
    version: &Version
): bool {
    gacha::version::check_valid(version);
    let admin_cap_id = sui::object::id(admin_cap);
    is_admin_eligible(registry, admin_cap_id)
}

/// Verify that an AdminCap is valid and eligible for a shared object
/// Checks: 1) AdminCap is for the correct shared object, 2) AdminCap is eligible
public fun verify_admin_cap(
    admin_cap: &AdminCap,
    registry: &AdminRegistry,
    shared_object_id: ID,
    version: &Version
) {
    gacha::version::check_valid(version);
    assert!(admin_cap.for_object == shared_object_id, E_WRONG_OBJECT);
    let admin_cap_id = sui::object::id(admin_cap);
    assert!(is_admin_eligible(registry, admin_cap_id), E_ADMIN_NOT_ELIGIBLE);
}

// ============================================================================
// ENTRY FUNCTIONS
// ============================================================================

/// Entry function to create and register an AdminCap for a shared object
/// Requires an AdminCap for the AdminRegistry shared object itself for authorization
/// AdminCap is soul-bound and transferred to the transaction sender
entry fun create_and_register_admin_cap_entry(
    admin_cap: &AdminCap,
    registry: &mut AdminRegistry,
    for_object: ID,
    version: &Version,
    ctx: &mut sui::tx_context::TxContext
) {
    gacha::version::check_valid(version);
    let new_admin_cap = create_and_register_admin_cap(admin_cap, registry, for_object, ctx);
    sui::transfer::transfer(new_admin_cap, ctx.sender());
}

/// Entry function to mark an AdminCap as eligible
/// Requires an AdminCap for the AdminRegistry shared object itself for authorization
entry fun mark_admin_eligible_entry(
    admin_cap: &AdminCap,
    registry: &mut AdminRegistry,
    target_admin_cap_id: ID,
    version: &Version
) {
    gacha::version::check_valid(version);
    // Verify admin_cap is authorized for the AdminRegistry shared object itself
    let registry_id = sui::object::id(registry);
    verify_admin_cap(admin_cap, registry, registry_id, version);
    mark_admin_eligible(registry, target_admin_cap_id);
}

/// Entry function to mark an AdminCap as not eligible
/// Requires an AdminCap for the AdminRegistry shared object itself for authorization
entry fun mark_admin_not_eligible_entry(
    admin_cap: &AdminCap,
    registry: &mut AdminRegistry,
    target_admin_cap_id: ID,
    version: &Version
) {
    gacha::version::check_valid(version);
    // Verify admin_cap is authorized for the AdminRegistry shared object itself
    let registry_id = sui::object::id(registry);
    verify_admin_cap(admin_cap, registry, registry_id, version);
    mark_admin_not_eligible(registry, target_admin_cap_id);
}


