# Makefile for Foundry Ethereum Development Toolkit

.PHONY: artengine  build test format snapshot anvil anvil-setup deploy deploy-anvil cast help subgraph clear-anvil-port

artengine:
	@echo "Generating assets..."
	@npx hardhat generate-assets --common 10 --limited 5 --rare 2 --unique 1 --ipfsnode $${BTP_IPFS}

chainId-anvil:
	@echo "Get chain id..."
	@CHAIN_ID=$(shell cast chain-id --rpc-url anvil) ; \
	echo "The chain ID is $$CHAIN_ID" ; \
	npx hardhat opensea-proxy-address --chainid $${CHAIN_ID}

build:
	@echo "Building with Forge..."
	@forge build

test:
	@echo "Testing with Forge..."
	@forge test

format:
	@echo "Formatting with Forge..."
	@forge fmt

snapshot:
	@echo "Creating gas snapshot with Forge..."
	@forge snapshot

anvil:
	@echo "Starting Anvil local Ethereum node..."
	@make clear-anvil-port
	@anvil

anvil-setup:
	@echo "Deploying with Forge to Anvil..."
	@IMAGES_EXIST=$$(npx hardhat check-images) ; \
	if [ "$$IMAGES_EXIST" = "true" ]; then \
		npx hardhat placeholder --ipfsnode $${BTP_IPFS} ; \
		npx hardhat opensea-proxy-address --chainid $(shell cast chain-id --rpc-url anvil) ;
	else \
		echo "\033[1;31mERROR: You have not created any assets, aborting...\033[0m"; \
		exit 1; \
	fi

deploy-anvil:
	@echo "Deploying with Forge to Anvil..."
	@forge create ./src/Counter.sol:Counter --rpc-url anvil --interactive | tee deployment-anvil.txt

deploy-btp:
	@eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
	args=""; \
	if [ ! -z "$${BTP_FROM}" ]; then \
		args="--unlocked --from $${BTP_FROM}"; \
	else \
		echo "\033[1;33mWARNING: No keys are activated on the node, falling back to interactive mode...\033[0m"; \
		echo ""; \
		args="--interactive"; \
	fi; \
	if [ ! -z "$${BTP_GAS_PRICE}" ]; then \
		args="$$args --gas-price $${BTP_GAS_PRICE}"; \
	fi; \
	if [ "$${BTP_EIP_1559_ENABLED}" = "false" ]; then \
		args="$$args --legacy"; \
	fi; \
	forge create ./src/Counter.sol:Counter $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} $$args --constructor-args "GenericToken" "GT" | tee deployment.txt;

script-anvil:
	@if [ ! -f deployment-anvil.txt ]; then \
		echo "\033[1;31mERROR: Contract was not deployed or the deployment-anvil.txt went missing.\033[0m"; \
		exit 1; \
	fi
	@DEPLOYED_ADDRESS=$$(grep "Deployed to:" deployment-anvil.txt | awk '{print $$3}') forge script script/Counter.s.sol:CounterScript ${EXTRA_ARGS} --rpc-url anvil -i=1

script:
	@if [ ! -f deployment.txt ]; then \
		echo "\033[1;31mERROR: Contract was not deployed or the deployment.txt went missing.\033[0m"; \
		exit 1; \
	fi
	@eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
	if [ -z "${BTP_FROM}" ]; then \
		echo "\033[1;33mWARNING: No keys are activated on the node, falling back to interactive mode...\033[0m"; \
		echo ""; \
		@DEPLOYED_ADDRESS=$$(grep "Deployed to:" deployment.txt | awk '{print $$3}') forge script script/Counter.s.sol:CounterScript ${EXTRA_ARGS} --rpc-url ${BTP_RPC_URL} -i=1; \
	else \
		@DEPLOYED_ADDRESS=$$(grep "Deployed to:" deployment.txt | awk '{print $$3}') forge script script/Counter.s.sol:CounterScript ${EXTRA_ARGS} --rpc-url ${BTP_RPC_URL} --unlocked --froms ${BTP_FROM}; \
	fi

cast:
	@echo "Interacting with EVM via Cast..."
	@cast $(SUBCOMMAND)

help:
	@echo "Forge help..."
	@forge --help
	@echo "Anvil help..."
	@anvil --help
	@echo "Cast help..."
	@cast --help

clear-anvil-port:
	-fuser -k -n tcp 8545