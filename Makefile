.PHONY: help build test publish clean format lint verify coverage sui-version

# Default target
help:
	@echo "Sui Move Project Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build        - Build the Move package"
	@echo "  make test         - Run all tests"
	@echo "  make publish      - Publish the package (requires active address)"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make format       - Format Move source files"
	@echo "  make lint         - Lint Move source files"
	@echo "  make verify       - Verify Move package (build + lint)"
	@echo "  make coverage     - Run tests with coverage"
	@echo "  make sui-version  - Show Sui CLI version"
	@echo "  make help         - Show this help message"

# Build the Move package
build:
	sui move build

# Run all tests
test:
	sui move test

# Publish the package
# Usage: make publish NETWORK=testnet
# Or: make publish NETWORK=mainnet
publish:
	@if [ -z "$(NETWORK)" ]; then \
		echo "Publishing to default network (devnet)"; \
		sui client publish --gas-budget 100000000; \
	else \
		echo "Publishing to $(NETWORK)"; \
		sui client publish --gas-budget 100000000 --$(NETWORK); \
	fi

# Clean build artifacts
clean:
	rm -rf .sui
	find . -name "*.move.mv" -delete
	find . -name "*.move.bak" -delete

# Format Move source files
format:
	sui move format

# Lint Move source files
lint:
	sui move lint

# Verify package (build + lint)
verify: build lint
	@echo "Package verification complete"

# Run tests with coverage
coverage:
	sui move test --coverage

# Show Sui CLI version
sui-version:
	sui --version

