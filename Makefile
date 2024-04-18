# Makefile for Foundry Ethereum Development Toolkit

.PHONY: artengine  build test format snapshot anvil anvil-setup anvil-collect-reserve anvil-launch-presale anvil-launch-publicsale anvil-reveal btp-setup btp-collect-reserve btp-launch-presale btp-launch-publicsale btp-reveal whitelist deploy deploy-anvil cast help subgraph clear-anvil-port

artengine:
	@echo "Generating assets..."
	@npx hardhat generate-assets --common 10 --limited 5 --rare 2 --unique 1 --ipfsnode $$BTP_IPFS

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
	@echo "Setting up collection on btp..."
	@IMAGES_EXIST=$$(npx hardhat check-images); \
	if [ $${IMAGES_EXIST} = "true" ]; then \
		PLACE_HOLDER="ipfs://$$(npx hardhat placeholder --ipfsnode ${BTP_IPFS}  | tr -d ' \n\t')"; \
		echo $${PLACE_HOLDER}; \
		CHAIN_ID=$$(cast chain-id --rpc-url $${BTP_RPC_URL}); \
		PROXY_ADDRESS=$$(npx hardhat opensea-proxy-address --chainid $$CHAIN_ID); \
		echo $${PROXY_ADDRESS}; \
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
		echo $${args};\
		forge create ./src/MetaDog.sol:MetaDog  --rpc-url $${BTP_RPC_URL} $$args --constructor-args "MetaDog" "MTD" $$PLACE_HOLDER $$PROXY_ADDRESS 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 | tee deployment.txt; \
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
	echo $$args; \
	cast send --rpc-url $${BTP_RPC_URL} $$args $$(grep "Deployed to:" deployment.txt | awk '{print $$3}') "collectReserves()"

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

subgraph:
	@echo "Deploying the subgraph..."
	@rm -Rf subgraph/subgraph.config.json
	@DEPLOYED_ADDRESS=$$(grep "Deployed to:" deployment.txt | awk '{print $$3}') TRANSACTION_HASH=$$(grep "Transaction hash:" deployment.txt | awk '{print $$3}') BLOCK_NUMBER=$$(cast receipt --rpc-url btp $${TRANSACTION_HASH} | grep "blockNumber" | awk '{print $$2}' | sed '2d') yq e -p=json -o=json '.datasources[0].address = env(DEPLOYED_ADDRESS) | .datasources[0].startBlock = env(BLOCK_NUMBER) | .chain = env(BTP_NODE_UNIQUE_NAME)' subgraph/subgraph.config.template.json > subgraph/subgraph.config.json
	@cd subgraph && npx graph-compiler --config subgraph.config.json --include node_modules/@openzeppelin/subgraphs/src/datasources subgraph/datasources --export-schema --export-subgraph
	@cd subgraph && yq e '.specVersion = "0.0.4"' -i generated/solidity-token-erc721-cards.subgraph.yaml
	@cd subgraph && yq e '.description = "Solidity Token ERC721"' -i generated/solidity-token-erc721-cards.subgraph.yaml
	@cd subgraph && yq e '.repository = "https://github.com/settlemint/solidity-token-erc721-cards"' -i generated/solidity-token-erc721-cards.subgraph.yaml
	@cd subgraph && yq e '.features = ["nonFatalErrors", "fullTextSearch", "ipfsOnEthereumContracts"]' -i generated/solidity-token-erc721-cards.subgraph.yaml
	@cd subgraph && npx graph codegen generated/solidity-token-erc721-cards.subgraph.yaml
	@cd subgraph && npx graph build generated/solidity-token-erc721-cards.subgraph.yaml
	@eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
	if [ -z "$${BTP_MIDDLEWARE}" ]; then \
		echo "\033[1;31mERROR: You have not launched a graph middleware for this smart contract set, aborting...\033[0m"; \
		exit 1; \
	else \
		cd subgraph; \
		npx graph create --node $${BTP_MIDDLEWARE} $${BTP_SCS_NAME}; \
		npx graph deploy --version-label v1.0.$$(date +%s) --node $${BTP_MIDDLEWARE} --ipfs $${BTP_IPFS}/api/v0 $${BTP_SCS_NAME} generated/solidity-token-erc721-cards.subgraph.yaml; \
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