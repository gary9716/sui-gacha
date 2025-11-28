# Agent Guidelines for Sui Gacha Project

## Rule 1: Security First

**Nothing is more important than security.**

Security must be the primary consideration in all code changes, design decisions, and implementations. Every function, every data structure, and every interaction must be evaluated through a security lens first.

### Security Principles:
- **Input Validation**: Always validate all inputs, especially user-provided data
- **Access Control**: Verify permissions and ownership before any state modifications
- **Reentrancy Protection**: Guard against reentrancy attacks in all state-changing operations
- **Overflow/Underflow**: Use safe math operations and check bounds
- **Resource Management**: Ensure proper resource cleanup and prevent resource leaks
- **Audit Trail**: Maintain clear audit trails for all critical operations
- **Least Privilege**: Grant minimum necessary permissions
- **Defense in Depth**: Implement multiple layers of security checks

### Security Checklist:
- [ ] Function visibility is minimal (started with `fun`)
- [ ] All inputs are validated
- [ ] Access controls are enforced
- [ ] No unauthorized state modifications
- [ ] Safe math operations used
- [ ] No reentrancy vulnerabilities
- [ ] Proper error handling
- [ ] Security implications documented

## Rule 2: Version Parameter Requirement

**Always include `version: &Version` as the first parameter of every public function.**

This ensures version compatibility and allows the system to verify that callers are using the correct version of the contract.

### Implementation Pattern:
```move
public fun example_function(
    version: &Version,
    // ... other parameters
    ctx: &mut TxContext
) {
    // Verify version compatibility first
    assert!(version::matches_current(version), E_INVALID_VERSION);
    
    // ... function implementation
}
```

### Why This Matters:
- **Version Compatibility**: Prevents calls from outdated clients
- **Upgrade Safety**: Allows graceful handling of version mismatches
- **Security**: Prevents exploitation of deprecated function versions
- **Auditability**: Makes version usage explicit in all transactions

### Exceptions:
- Internal/private functions (not exposed publicly)
- View functions that don't modify state (may be optional, but recommended for consistency)
- Entry functions that initialize version objects themselves
- Migrate functions (package upgrade migration functions)

## Rule 3: Function Visibility - Minimal Permission Principle

**Function visibility is a critical security decision. Always start with the most restrictive visibility and only increase it when absolutely necessary.**

The visibility decorator before a function determines who can call it, which directly impacts the attack surface and security of your contract.

### Visibility Levels (Most Restrictive to Least Restrictive):

1. **`fun` (Private/Internal)** - Default, most secure
   - Only callable within the same module
   - Use for: Internal helpers, utility functions, implementation details
   - **Default choice** - start here unless you have a specific reason to expose

2. **`public(package)` (Package-level)** - Moderate security
   - Callable only by other modules in the same package
   - Use for: Functions that need to be shared between modules but not exposed externally
   - Example: Internal state management functions that multiple modules need

3. **`public` (Public)** - Least restrictive, highest risk
   - Callable by anyone, from any module, in any package
   - Use for: Functions that must be part of the public API
   - **Requires version parameter** (see Rule 2)
   - Requires thorough security review

4. **`entry` (Entry Point)** - Special case
   - Public function that can be called directly in transactions
   - Use for: User-facing transaction entry points
   - **Requires version parameter** if modifying state
   - Requires maximum security scrutiny

### Decision Tree:

```
Start: Do you need this function?
  │
  ├─ No → Don't create it
  │
  └─ Yes → Can it be private (fun)?
      │
      ├─ Yes → Use `fun` (DEFAULT)
      │
      └─ No → Does it need to be called by other modules in this package?
          │
          ├─ Yes → Use `public(package)`
          │
          └─ No → Does it need to be part of the public API?
              │
              ├─ No → Reconsider: Why isn't it private?
              │
              └─ Yes → Is it a transaction entry point?
                  │
                  ├─ Yes → Use `entry` (with version check)
                  │
                  └─ No → Use `public` (with version check)
```

### Security Principles:

1. **Start Private**: Default to `fun` (private) unless you have a compelling reason to expose
2. **Justify Exposure**: Every `public` or `public(package)` function must have a documented reason
3. **Minimal Surface**: Smaller public API = smaller attack surface
4. **Review Public Functions**: All `public` and `entry` functions require security review
5. **Version Protection**: All `public` functions must include version parameter (Rule 2)

### Examples:

```move
// ✅ GOOD: Private helper function
fun calculate_pity_rate(base_rate: u64, pity_count: u64): u64 {
    // Internal calculation, no need to expose
}

// ✅ GOOD: Package-level function for internal module communication
public(package) fun update_pity_state(
    player: &mut Player,
    banner_id: ID,
    ctx: &mut TxContext
) {
    // Shared between modules in package, but not public API
}

// ✅ GOOD: Public function with version check
public fun get_pity(
    version: &Version,
    player: &Player,
    banner_id: ID,
    rarity: u8
): u64 {
    version::check_valid(version);
    // Public read-only function
}

// ❌ BAD: Public function without version check
public fun update_pity(player: &mut Player, banner_id: ID) {
    // Missing version parameter - security risk!
}

// ❌ BAD: Unnecessarily public
public fun internal_helper(x: u64): u64 {
    // Should be `fun` (private) - no reason to expose
}
```

### Security Checklist for Function Visibility:

- [ ] Started with `fun` (private) as default
- [ ] Justified any `public` or `public(package)` visibility
- [ ] All `public` functions include version parameter
- [ ] All `entry` functions have security review
- [ ] Minimal public API surface area
- [ ] Internal helpers are private
- [ ] State-modifying functions have proper access controls

### Questions to Ask Before Making a Function Public:

1. **Why does this need to be public?** - What's the specific use case?
2. **Can it be `public(package)` instead?** - Does it only need package-level access?
3. **Can it be private?** - Is there a way to keep it internal?
4. **What are the security implications?** - What can an attacker do with this?
5. **Is input validation sufficient?** - Are all parameters validated?
6. **Are access controls enforced?** - Can unauthorized users call this?
7. **Does it modify state?** - If yes, is the version parameter included?

---

**Remember: Every public function is a potential attack vector. Make visibility decisions carefully and deliberately.**

## Rule 4: Module Organization - Structured Code Layout

**Every module must follow a consistent structure to improve readability, maintainability, and security review.**

A well-organized module makes it easier to understand the codebase, identify security boundaries, and maintain the code over time.

### Module Structure Order:

1. **Structs** (First)
   - All struct definitions
   - Public structs first, then private/internal structs
   - Group related structs together

2. **Constants** (Second)
   - Error codes
   - Configuration constants
   - Magic numbers
   - Group by purpose (errors, config, etc.)

3. **Functions** (Last)
   - Organized by visibility level:
     - **Private functions** (`fun`) - Internal helpers, utilities
     - **Protected functions** (`public(package)`) - Package-level access
     - **Public functions** (`public` / `entry`) - Public API

### Module Template:

```move
module gacha::example;

use sui::...;

// ============================================================================
// STRUCTS
// ============================================================================

/// Public struct for external use
public struct PublicStruct has key {
    id: UID,
    // ...
}

/// Internal struct for module use
struct InternalStruct has store {
    // ...
}

// ============================================================================
// CONSTANTS
// ============================================================================

/// Error codes
const E_INVALID_INPUT: u64 = 0;
const E_UNAUTHORIZED: u64 = 1;

/// Configuration constants
const MAX_VALUE: u64 = 1000;
const DEFAULT_RATE: u64 = 50;

// ============================================================================
// PRIVATE FUNCTIONS
// ============================================================================

/// Internal helper function
fun private_helper(x: u64): u64 {
    // ...
}

/// Internal utility function
fun calculate_value(base: u64): u64 {
    // ...
}

// ============================================================================
// PROTECTED FUNCTIONS (public(package))
// ============================================================================

/// Package-level function for internal module communication
public(package) fun update_state(
    obj: &mut PublicStruct,
    value: u64
) {
    // ...
}

// ============================================================================
// PUBLIC FUNCTIONS
// ============================================================================

/// Public function with version check
public fun get_value(
    version: &Version,
    obj: &PublicStruct
): u64 {
    version::check_valid(version);
    // ...
}

/// Entry function for transactions
entry fun execute(
    version: &Version,
    obj: &mut PublicStruct,
    ctx: &mut TxContext
) {
    version::check_valid(version);
    // ...
}
```

### Organization Principles:

1. **Clear Separation**: Use comment separators to clearly delineate sections
2. **Logical Grouping**: Group related structs, constants, and functions together
3. **Visibility Order**: Functions ordered from most restrictive to least restrictive
4. **Consistency**: Follow the same structure across all modules
5. **Documentation**: Each section should be clearly documented

### Benefits:

- **Security Review**: Easy to identify public attack surface (public functions)
- **Maintainability**: Clear structure makes code easier to navigate
- **Onboarding**: New developers can quickly understand module organization
- **Code Review**: Reviewers can focus on public functions first
- **Refactoring**: Easier to identify what can be safely changed

### Checklist:

- [ ] Structs are defined first
- [ ] Constants are defined second
- [ ] Functions are organized by visibility (private → protected → public)
- [ ] Comment separators used to mark sections
- [ ] Related items are grouped together
- [ ] Public functions are clearly separated and documented

---

**Remember: Consistent organization is the foundation of maintainable and secure code.**

## Additional Guidelines

### Code Quality
- Follow Sui Move coding conventions: https://docs.sui.io/concepts/sui-move-concepts/conventions
- Follow module organization structure (Rule 4): Structs → Constants → Functions (private → protected → public)
- Write clear, self-documenting code
- Add comments for complex logic
- Use meaningful variable and function names

### Testing
- Write comprehensive tests for all new functions
- Test edge cases and error conditions
- Test security boundaries
- Verify version compatibility in tests

### Documentation
- Document all public functions
- Explain security considerations
- Note any assumptions or limitations
- Update DESIGN.md for architectural changes

### Error Handling
- Use descriptive error codes
- Provide clear error messages
- Handle all error paths
- Never expose sensitive information in errors

### Performance
- Optimize gas usage where possible
- Avoid unnecessary on-chain operations
- Batch operations when appropriate
- Consider storage costs

## Workflow

1. **Security Review First**: Before implementing any feature, consider security implications
2. **Module Structure**: Organize code following Rule 4 (Structs → Constants → Functions)
3. **Visibility Decision**: Start with `fun` (private), only increase visibility when necessary
4. **Version Check**: Ensure version parameter is included in all public functions
5. **Implementation**: Write code following security-first principles
6. **Testing**: Test thoroughly, especially security boundaries
7. **Documentation**: Update relevant documentation
8. **Review**: Self-review with security checklist

## Questions to Ask

Before making any change, ask:
- Does this introduce any security vulnerabilities?
- Is the function visibility minimal (started with `fun`)?
- Is the version parameter included (for public functions)?
- Are all inputs validated?
- Are access controls properly enforced?
- What are the failure modes?
- How can this be exploited?
- Is the error handling secure?

---

**Remember: Security is not optional. It's the foundation of everything we build.**

