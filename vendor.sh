#!/bin/bash

# Vendor dependencies - Download all dependencies to vendor/

echo "📦 Downloading dependencies to vendor directory..."

# Download dependencies and create vendor directory
go mod download
go mod vendor

if [ $? -eq 0 ]; then
    echo "✓ Dependencies vendored successfully!"
    echo "All dependencies are now in ./vendor directory"
    echo ""
    echo "Build with vendored dependencies:"
    echo "  go build -mod=vendor -o rime_mate main.go"
else
    echo "✗ Vendor failed"
    exit 1
fi
