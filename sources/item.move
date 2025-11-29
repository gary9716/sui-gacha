module gacha::item;

use sui::table::{Self, Table};
use gacha::version::Version;
use gacha::rarity;
use std::string::{Self, String};

// ============================================================================
// STRUCTS
// ============================================================================

/// Item type enumeration
/// Represents different categories of items in the gacha system
public struct ItemType has store, copy, drop {
    /// Item type code (0 = Character, 1 = Equipment, 2 = Material, 3 = Consumable, etc.)
    type_code: u8,
}

/// Item metadata stored as key-value pairs
/// Allows flexible storage of item properties (stats, abilities, etc.)
public struct ItemMetadata has store {
    /// Maps property name -> property value
    properties: Table<String, String>,
}

/// Generic item struct
/// Represents any item that can be obtained from gacha pulls
public struct Item has key, store {
    id: UID,
    /// Unique item identifier
    item_id: ID,
    /// Display name
    name: String,
    /// Rarity tier (1-6 stars, higher = rarer)
    rarity: u8,
    /// Item type (Character, Equipment, Material, Consumable, etc.)
    item_type: ItemType,
    /// Flexible metadata storage for item properties
    metadata: ItemMetadata,
    /// Whether this item is currently featured in a banner
    is_featured: bool,
}

// ============================================================================
// CONSTANTS
// ============================================================================

/// Error codes
const E_INVALID_RARITY: u64 = 0;

// ============================================================================
// PRIVATE FUNCTIONS
// ============================================================================

/// Create a new empty ItemMetadata
fun new_metadata(ctx: &mut sui::tx_context::TxContext): ItemMetadata {
    ItemMetadata {
        properties: table::new(ctx),
    }
}

/// Create a new ItemType
fun new_item_type(type_code: u8): ItemType {
    ItemType {
        type_code,
    }
}

/// Validate rarity tier using the rarity module
fun validate_rarity(rarity: u8): bool {
    rarity::is_valid_rarity(rarity)
}

/// Set a metadata property
fun set_property(metadata: &mut ItemMetadata, key: String, value: String) {
    if (table::contains(&metadata.properties, key)) {
        let prop = table::borrow_mut(&mut metadata.properties, key);
        *prop = value;
    } else {
        table::add(&mut metadata.properties, key, value);
    };
}

/// Get a metadata property
/// Returns empty string if property doesn't exist
fun get_property(metadata: &ItemMetadata, key: String): String {
    if (table::contains(&metadata.properties, key)) {
        *table::borrow(&metadata.properties, key)
    } else {
        string::utf8(vector::empty<u8>())
    }
}

// ============================================================================
// PROTECTED FUNCTIONS (public(package))
// ============================================================================

/// Create a new item
/// This is a package-level function for internal use
public(package) fun create(
    item_id: ID,
    name: String,
    rarity: u8,
    item_type_code: u8,
    ctx: &mut sui::tx_context::TxContext
): Item {
    assert!(validate_rarity(rarity), E_INVALID_RARITY);
    
    Item {
        id: sui::object::new(ctx),
        item_id,
        name,
        rarity,
        item_type: new_item_type(item_type_code),
        metadata: new_metadata(ctx),
        is_featured: false,
    }
}

/// Set item as featured
public(package) fun set_featured(item: &mut Item, featured: bool) {
    item.is_featured = featured;
}

/// Set a metadata property on an item
public(package) fun set_metadata_property(
    item: &mut Item,
    key: String,
    value: String
) {
    set_property(&mut item.metadata, key, value);
}

/// Get a metadata property from an item
public(package) fun get_metadata_property(
    item: &Item,
    key: String
): String {
    get_property(&item.metadata, key)
}

// ============================================================================
// PUBLIC FUNCTIONS
// ============================================================================

/// Get item ID
public fun get_item_id(item: &Item, version: &Version): ID {
    gacha::version::check_valid(version);
    item.item_id
}

/// Get item name
public fun get_name(item: &Item, version: &Version): String {
    gacha::version::check_valid(version);
    item.name
}

/// Get item rarity tier
public fun get_rarity(item: &Item, version: &Version): u8 {
    gacha::version::check_valid(version);
    item.rarity
}

/// Get item type code
public fun get_item_type_code(item: &Item, version: &Version): u8 {
    gacha::version::check_valid(version);
    item.item_type.type_code
}

/// Check if item is featured
public fun is_featured(item: &Item, version: &Version): bool {
    gacha::version::check_valid(version);
    item.is_featured
}

/// Get metadata property (public read access)
public fun get_metadata(item: &Item, version: &Version, key: String): String {
    gacha::version::check_valid(version);
    get_property(&item.metadata, key)
}

/// Check if item has a specific metadata property
public fun has_metadata(item: &Item, version: &Version, key: String): bool {
    gacha::version::check_valid(version);
    table::contains(&item.metadata.properties, key)
}

// ============================================================================
// ITEM TYPE HELPERS
// ============================================================================

/// Create an ItemType with a custom type code
/// Users should define their own item type constants and use this function
/// Example: create_item_type(mygame::item_types::MY_TYPE_WEAPON)
public fun create_item_type(type_code: u8): ItemType {
    ItemType { type_code }
}

/// Check if item has a specific item type
/// Users should define their own item type constants and use this function
/// Example: is_item_type(item, version, mygame::item_types::MY_TYPE_WEAPON)
public fun is_item_type(item: &Item, version: &Version, type_code: u8): bool {
    gacha::version::check_valid(version);
    item.item_type.type_code == type_code
}

// ============================================================================
// RARITY HELPERS
// ============================================================================

/// Check if item has a specific rarity tier
/// Users should define their own rarity constants and use this function
/// Example: is_rarity(item, version, mygame::rarities::MY_RARITY_EPIC)
public fun is_rarity(item: &Item, version: &Version, rarity: u8): bool {
    gacha::version::check_valid(version);
    item.rarity == rarity
}

/// Check if item rarity is valid
public fun has_valid_rarity(item: &Item, version: &Version): bool {
    gacha::version::check_valid(version);
    rarity::is_valid_rarity(item.rarity)
}

/// Compare item rarity with another rarity tier
/// Returns true if item rarity is higher than the given rarity
public fun is_higher_rarity_than(item: &Item, version: &Version, rarity: u8): bool {
    gacha::version::check_valid(version);
    rarity::is_higher_rarity(item.rarity, rarity)
}

/// Compare item rarity with another rarity tier
/// Returns true if item rarity is lower than the given rarity
public fun is_lower_rarity_than(item: &Item, version: &Version, rarity: u8): bool {
    gacha::version::check_valid(version);
    rarity::is_lower_rarity(item.rarity, rarity)
}

/// Compare item rarity with another rarity tier
/// Returns true if item rarity is equal to the given rarity
public fun is_equal_rarity_to(item: &Item, version: &Version, rarity: u8): bool {
    gacha::version::check_valid(version);
    rarity::is_equal_rarity(item.rarity, rarity)
}

// Note: Rarity names are not hardcoded. Users should implement their own
// rarity naming system based on their game design, potentially using item metadata.

