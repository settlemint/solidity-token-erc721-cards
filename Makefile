# Makefile for Foundry Ethereum Development Toolkit

.PHONY: artengine  build test format snapshot anvil anvil-setup anvil-collect-reserve anvil-launch-presale anvil-launch-publicsale anvil-reveal btp-setup btp-collect-reserve btp-launch-presale btp-launch-publicsale btp-reveal whitelist deploy deploy-anvil cast help subgraph clear-anvil-port

artengine:
	@echo "Generating assets..."
	@npx hardhat generate-assets --common 10 --limited 5 --rare 2 --unique 1 --ipfsnode $${BTP_IPFS}

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
	@echo "Setting up collection on Anvil..."
	@IMAGES_EXIST=$$(npx hardhat check-images); \
	if [ "$$IMAGES_EXIST" = "true" ]; then \
		PLACE_HOLDER=$$(npx hardhat placeholder --ipfsnode $${BTP_IPFS}); \
		CHAIN_ID=$$(cast chain-id --rpc-url anvil); \
		PROXY_ADDRESS=$$(npx hardhat opensea-proxy-address --chainid $$CHAIN_ID); \
		forge create ./src/MetaDog.sol:MetaDog --rpc-url anvil --interactive --constructor-args "MetaDog" "MTD" "ipfs://$${PLACE_HOLDER}" "$${PROXY_ADDRESS}" "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" | tee deployment-anvil.txt; \
	else \
		echo "\033[1;31mERROR: You have not created any assets, aborting...\033[0m"; \
		exit 1; \
	fi

anvil-collect-reserve:
	@echo "Collecting reserve..."
	@cast send --rpc-url anvil $$(grep "Deployed to:" deployment-anvil.txt | awk '{print $$3}') "collectReserves()" --value 0 --interactive

whitelist:
	@npx hardhat whitelist

anvil-launch-presale:
	@echo "Launching presale..."
	@cast send --rpc-url anvil $$(grep "Deployed to:" deployment-anvil.txt | awk '{print $$3}') "setWhitelistMerkleRoot(bytes32)" $$(jq -r '.root' ./assets/generated/whitelist.json) --value 0 --interactive

anvil-launch-publicsale:
	@echo "Launching presale..."
	@cast send --rpc-url anvil $$(grep "Deployed to:" deployment-anvil.txt | awk '{print $$3}') "startPublicSale()" --value 0 --interactive

anvil-reveal:
	@echo "Revealing..."
	@IMAGES_EXIST=$$(npx hardhat check-images); \
	if [ "$$IMAGES_EXIST" = "true" ]; then \
		REVEAL_TOKEN_URI=$$(npx hardhat reveal --ipfsnode $${BTP_IPFS}); \
		TOKEN_ADDRESS=$$(grep "Deployed to:" deployment-anvil.txt | awk '{print $$3}') REVEAL_TOKEN_URI=$$REVEAL_TOKEN_URI forge script script/PublicSaleScript.s.sol:PublicSaleScript --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast --rpc-url anvil; \
	else \
		echo "\033[1;31mERROR: You have not created any assets, aborting...\033[0m"; \
		exit 1; \
	fi

btp-setup:
	@echo "Setting up collection on Anvil..."
	@IMAGES_EXIST=$$(npx hardhat check-images); \
	if [ "$$IMAGES_EXIST" = "true" ]; then \
		PLACE_HOLDER=$$(npx hardhat placeholder --ipfsnode $${BTP_IPFS}); \
		CHAIN_ID=$$(cast chain-id --rpc-url anvil); \
		PROXY_ADDRESS=$$(npx hardhat opensea-proxy-address --chainid $$CHAIN_ID); \
		eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
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
		forge create ./src/MetaDog.sol:MetaDog $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} $$args --constructor-args "MetaDog" "MTD" "ipfs://$${PLACE_HOLDER}" "$${PROXY_ADDRESS}" "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" | tee deployment.txt; \
	else \
		echo "\033[1;31mERROR: You have not created any assets, aborting...\033[0m"; \
		exit 1; \
	fi

btp-collect-reserve:
	@echo "Collecting reserve..."
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
	cast send $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} $$args $$(grep "Deployed to:" deployment.txt | awk '{print $$3}') "collectReserves()" --value 0

btp-launch-presale:
	@echo "Launching presale..."
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
	cast send $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} $$args $$(grep "Deployed to:" deployment.txt | awk '{print $$3}') "setWhitelistMerkleRoot(bytes32)" $$(jq -r '.root' ./assets/generated/whitelist.json) --value 0 --interactive

btp-launch-publicsale:
	@echo "Launching presale..."
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
	cast send $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} $$args $$(grep "Deployed to:" deployment.txt | awk '{print $$3}') "startPublicSale()" --value 0 --interactive

btp-reveal:
	@echo "Revealing..."
	@IMAGES_EXIST=$$(npx hardhat check-images); \
	if [ "$$IMAGES_EXIST" = "true" ]; then \
		REVEAL_TOKEN_URI=$$(npx hardhat reveal --ipfsnode $${BTP_IPFS}); \
		eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
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
		TOKEN_ADDRESS=$$(grep "Deployed to:" deployment-anvil.txt | awk '{print $$3}') REVEAL_TOKEN_URI=$$REVEAL_TOKEN_URI forge script script/PublicSaleScript.s.sol:PublicSaleScript $${EXTRA_ARGS} $$args --rpc-url ${BTP_RPC_URL}; \
	else \
		echo "\033[1;31mERROR: You have not created any assets, aborting...\033[0m"; \
		exit 1; \
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