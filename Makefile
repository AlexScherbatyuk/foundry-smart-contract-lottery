-include .env

.PHONY: all test clean deploy fund install snapshot format anvil 

all: clean remove install update build

fmt:
	forge fmt

build: fmt
	forge build

install :; forge install cyfrin/foundry-devops@0.2.2 && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 && forge 	install foundry-rs/forge-std@v1.8.2 && forge install transmissions11/solmate@v6


deploy:
	@@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url 127.0.0.1:8545 --account devKey --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --password-file .password --broadcast -vvvv


deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account devKey  --sender 0x667c1aBD4E25BE048b8217F90Fc576780CCa8218 --password-file .password --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

clean  :; forge clean

snapshot :; forge snapshot