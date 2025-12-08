#!/bin/bash
# Setup script for Foundry Testing Portfolio
# Run this script to initialize all week projects with forge-std

set -e

echo "🔧 Setting up Foundry Testing Portfolio..."
echo ""

# Check if Foundry is installed
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry is not installed. Please install it first:"
    echo "   curl -L https://foundry.paradigm.xyz | bash"
    echo "   foundryup"
    exit 1
fi

echo "✅ Foundry detected: $(forge --version)"
echo ""

# Array of week directories
weeks=(
    "week-01-storage"
    "week-02-bank"
    "week-03-counter"
    "week-04-timelock"
    "week-05-voting"
    "week-06-miniexchange"
)

# Initialize each week
for week in "${weeks[@]}"; do
    echo "📁 Setting up $week..."
    
    cd "$week"
    
    # Install forge-std if not present
    if [ ! -d "lib/forge-std" ]; then
        forge install foundry-rs/forge-std --no-commit
    fi
    
    # Build to verify setup
    forge build --silent
    
    echo "   ✅ $week ready!"
    
    cd ..
done

echo ""
echo "🎉 All weeks initialized successfully!"
echo ""
echo "To get started:"
echo "  cd week-01-storage"
echo "  forge test -vvv"
echo ""
echo "Happy testing! 🧪"
