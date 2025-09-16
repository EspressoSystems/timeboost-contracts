#!/bin/bash
# Bash script to assist with deploying the KeyManager contract

set -e

# Script options
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo "  --dry-run    test deployment"
            echo ""
            echo "Set MANAGER_ADDRESS env var"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# load .env
if [ -f ".env" ]; then
    echo "Loading .env file..."
    set -a
    source .env
    set +a
else
    echo "Using environment variables"
fi

# Check if required environment variables are set
if [ -z "$MANAGER_ADDRESS" ]; then
    echo "Need MANAGER_ADDRESS env var"
    exit 1
fi

# defaults
RPC_URL=${RPC_URL:-"http://localhost:8545"}
ACCOUNT_INDEX=${ACCOUNT_INDEX:-0}
MNEMONIC=${MNEMONIC:-"test test test test test test test test test test test junk"}

echo "Deploying KeyManager..."
echo "Manager: $MANAGER_ADDRESS"
echo "RPC: $RPC_URL"
echo

# Set environment variable for the script
export MANAGER_ADDRESS=$MANAGER_ADDRESS

echo "Testing RPC connection..."
if ! curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' "$RPC_URL" > /dev/null; then
    echo "Can't connect to $RPC_URL"
    exit 1
fi

echo "Running..."

# Build forge command with dry-run support
FORGE_CMD="forge script script/DeployKeyManager.s.sol:DeployKeyManager --rpc-url $RPC_URL"

if [ "$DRY_RUN" = true ]; then
    echo "Running simulation (dry run)"
    FORGE_CMD="$FORGE_CMD -- --dry-run"
else
    FORGE_CMD="$FORGE_CMD --broadcast"
fi

# fix mnemonic quotes
MNEMONIC_TO_USE="$MNEMONIC"
if [[ "$MNEMONIC" == \"*\" ]]; then
    MNEMONIC_TO_USE="${MNEMONIC#\"}"
    MNEMONIC_TO_USE="${MNEMONIC_TO_USE%\"}"
fi

# Execute the forge command
timeout 60 $FORGE_CMD --mnemonics "$MNEMONIC_TO_USE" --mnemonic-indexes "$ACCOUNT_INDEX"
DEPLOYMENT_EXIT_CODE=$?

if [ $DEPLOYMENT_EXIT_CODE -eq 124 ]; then
    echo "Command timed out - check RPC connection"
    exit 1
fi

if [ $DEPLOYMENT_EXIT_CODE -eq 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "Looks good. Run without --dry-run to deploy."
    else
        echo "Done. Check broadcast/ for details."
    fi
else
    if [ "$DRY_RUN" = true ]; then
        echo "Simulation failed (exit $DEPLOYMENT_EXIT_CODE)"
    else
        echo "Deployment failed (exit $DEPLOYMENT_EXIT_CODE)"
    fi
    exit $DEPLOYMENT_EXIT_CODE
fi
