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

## Additional Guidelines

### Code Quality
- Follow Sui Move coding conventions: https://docs.sui.io/concepts/sui-move-concepts/conventions
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
2. **Version Check**: Ensure version parameter is included in all public functions
3. **Implementation**: Write code following security-first principles
4. **Testing**: Test thoroughly, especially security boundaries
5. **Documentation**: Update relevant documentation
6. **Review**: Self-review with security checklist

## Questions to Ask

Before making any change, ask:
- Does this introduce any security vulnerabilities?
- Is the version parameter included?
- Are all inputs validated?
- Are access controls properly enforced?
- What are the failure modes?
- How can this be exploited?
- Is the error handling secure?

---

**Remember: Security is not optional. It's the foundation of everything we build.**

