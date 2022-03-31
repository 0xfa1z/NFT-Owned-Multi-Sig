#!/usr/bin/env bash

set -eo pipefail

if [[ ${DEBUG} ]]; then 
	set -x
fi

# All contracts are output to `out/addresses.json` by default
OUT_DIR=${OUT_DIR:-$PWD/out}
ADDRESSES_FILE=${ADDRESSES_FILE:-$OUT_DIR/"addresses.json"}
# default to localhost rpc
ETH_RPC_URL=${ETH_RPC_URL:-http://localhost:8545}

# green log helper
GREEN='\033[0;32m'
NC='\033[0m' # No Color
log() {
	printf '%b\n' "${GREEN}${*}${NC}"
	echo ""
}

# Coloured output helpers
if command -v tput >/dev/null 2>&1; then
	if [ $(($(tput colors 2>/dev/null))) -ge 8 ]; then
		# Enable colors
		TPUT_RESET="$(tput sgr 0)"
		TPUT_YELLOW="$(tput setaf 3)"
		TPUT_RED="$(tput setaf 1)"
		TPUT_BLUE="$(tput setaf 4)"
		TPUT_GREEN="$(tput setaf 2)"
		TPUT_WHITE="$(tput setaf 7)"
		TPUT_BOLD="$(tput bold)"
	fi
fi

# ensure ETH_FROM is set and give a meaningful error message
if [[ -z ${ETH_FROM} ]]; then
	echo "ETH_FROM not found, please set it and re-run the last command."
	exit 1
fi

# Make sure address is checksummed
if [ "$ETH_FROM" != "$(seth --to-checksum-address "$ETH_FROM")" ]; then
	echo "ETH_FROM not checksummed, please format it with 'seth --to-checksum-address <address>'"
	exit 1
fi

# Setup addresses file
cat >"$ADDRESSES_FILE" <<EOF
{
    "DEPLOYER": "$ETH_FROM"
}
EOF

# Call as `ETH_FROM=0x... ETH_RPC_URL=<url> deploy ContractName arg1 arg2 arg3`
# (or omit the env vars if you have already set them)
deploy() {
	NAME=$1
	ARGS=${@:2}

	# find file path
	CONTRACT_PATH=$(find ./src -name $NAME.sol)
	CONTRACT_PATH=${CONTRACT_PATH:2}

	# select the filename and the contract in it
	PATTERN=".contracts[\"$CONTRACT_PATH\"].$NAME"

	# get the constructor's signature
	ABI=$(jq -r "$PATTERN.abi" out/dapp.sol.json)
	SIG=$(echo "$ABI" | seth --abi-constructor)

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" out/dapp.sol.json)

	# estimate gas
	GAS=$(seth estimate --create "$BYTECODE" "$SIG" $ARGS --rpc-url "$ETH_RPC_URL")

	# deploy
	ADDRESS=$(dapp create "$NAME" $ARGS -- --gas "$GAS" --rpc-url "$ETH_RPC_URL")

	# save the addrs to the json
	# TODO: It'd be nice if we could evolve this into a minimal versioning system
	# e.g. via commit / chainid etc.
	saveContract "$NAME" "$ADDRESS"

	echo "$ADDRESS"
}

# Call as `saveContract ContractName 0xYourAddress` to store the contract name
# & address to the addresses json file
saveContract() {
	# create an empty json if it does not exist
	if [[ ! -e $ADDRESSES_FILE ]]; then
		echo "{}" >"$ADDRESSES_FILE"
	fi
	result=$(cat "$ADDRESSES_FILE" | jq -r ". + {\"$1\": \"$2\"}")
	printf %s "$result" >"$ADDRESSES_FILE"
}

estimate_gas() {
	NAME=$1
	ARGS=${@:2}
	# select the filename and the contract in it
	PATTERN=".contracts[\"src/$NAME.sol\"].$NAME"

	# get the constructor's signature
	ABI=$(jq -r "$PATTERN.abi" out/dapp.sol.json)
	SIG=$(echo "$ABI" | seth --abi-constructor)

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" out/dapp.sol.json)

	# estimate gas
	GAS=$(seth estimate --create "$BYTECODE" "$SIG" $ARGS --rpc-url "$ETH_RPC_URL")

	# URL for gwei per gas units
	URL=https://data-api.defipulse.com/api/v1/egs/api/ethgasAPI.json

	# Factor to Calculate Eth from Price in Gwei
	ETH=0.000000001

	TXPRICE_RESPONSE=$(curl -sL $URL)
	response=$(jq '.statusCode' <<<"$TXPRICE_RESPONSE")
	if [[ -z $response ]]; then
		echo "Could not get gas information from ${TPUT_BOLD}defi-pulse.com${TPUT_RESET}: $URL"
		echo "response code: $response"
	else
		rapid=$(expr $(($(jq '.fastest' <<<"$TXPRICE_RESPONSE"))) / 10)
		fast=$(expr $(($(jq '.fast' <<<"$TXPRICE_RESPONSE"))) / 10)
		standard=$(expr $(($(jq '.average' <<<"$TXPRICE_RESPONSE"))) / 10)
		slow=$(expr $(($(jq '.safeLow' <<<"$TXPRICE_RESPONSE"))) / 10)
		# basefee$(($(jq '.blockPrices[0].baseFeePerGas' <<<"$TXPRICE_RESPONSE")))
		echo "Gas prices from defi-pulse.com: $URL"
		echo " \
     ${TPUT_RED}Rapid: $rapid gwei ${TPUT_RESET}
     ${TPUT_YELLOW}Fast: $fast gwei
     ${TPUT_BLUE}Standard: $standard gwei
     ${TPUT_GREEN}Slow: $slow gwei${TPUT_RESET}" | column -t
		size=$(contract_size "$NAME")
		echo "Estimated Gas cost for deployment of $NAME: $GAS units of gas"
		echo "Contract Size: ${size} bytes"
		echo "Total cost for deployment:"
		rapid_cost=$(echo "scale=5; $GAS*$rapid*$ETH" | bc)
		fast_cost=$(echo "scale=5; $GAS*$fast*$ETH" | bc)
		standard_cost=$(echo "scale=5; $GAS*$standard*$ETH" | bc)
		slow_cost=$(echo "scale=5; $GAS*$slow*$ETH" | bc)
		echo " \
     ${TPUT_RED}Rapid: $rapid_cost ETH ${TPUT_RESET}
     ${TPUT_YELLOW}Fast: $fast_cost ETH
     ${TPUT_BLUE}Standard: $standard_cost ETH
     ${TPUT_GREEN}Slow: $slow_cost ETH ${TPUT_RESET}" | column -t
	fi
}

contract_size() {
	NAME=$1
	ARGS=${@:2}
	# select the filename and the contract in it
	PATTERN=".contracts[\"src/$NAME.sol\"].$NAME"

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" out/dapp.sol.json)
	length=$(echo "$BYTECODE" | wc -m)
	echo $(($length / 2))
}
