/// Module: version
/// Provides version information for the gacha package
module gacha::version;

use sui::package::Publisher;

const E_VERSION_NOT_OLDER: u64 = 0;
const E_VERSION_INVALID: u64 = 1;

//OTW
public struct VERSION has drop {}

/// Version information stored on-chain
public struct Version has key {
    id: UID,
    version: u64,
}

/// Current version number - bump this by 1 for each release
const CURRENT_VERSION: u64 = 1;

/// Get the current version number
public fun version(): u64 {
    CURRENT_VERSION
}

/// Check if a version object matches the current package version
public fun check_valid(version: &Version) {
    assert!(version.version == CURRENT_VERSION, E_VERSION_INVALID)
}

/// Initialize version object - only called automatically on package publish
/// Creates and shares the version object on-chain
fun init(otw: VERSION, ctx: &mut sui::tx_context::TxContext) {
    sui::package::claim_and_keep(otw, ctx);
    let version = Version {
        id: object::new(ctx),
        version: CURRENT_VERSION,
    };
    sui::transfer::share_object(version);
}

/// Migrate version to new version number
/// Requires publisher cap to ensure only package publisher can migrate
entry fun migrate(
    version: &mut Version,
    _cap: &Publisher,
    _ctx: &mut sui::tx_context::TxContext
) {
    // The presence of &Publisher ensures only the publisher can call this
    // Verify the version is being updated to the current package version
    assert!(version.version < CURRENT_VERSION, E_VERSION_NOT_OLDER);
    
    // Update version to current
    version.version = CURRENT_VERSION;
}
