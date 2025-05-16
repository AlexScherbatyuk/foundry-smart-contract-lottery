.PHONY: fmt build test

fmt:
	@forge fmt

build: fmt
	@forge build

build: fmt
	@forge test