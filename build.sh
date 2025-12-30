#!/bin/bash

# Build script - Compile for macOS executable

echo "Building rime-mate..."

# Set output filename
OUTPUTPATH="./output"
OUTPUT="rime-mate"

# Build for macOS executable
# GOOS=darwin GOARCH=amd64 - for Intel Mac
# GOOS=darwin GOARCH=arm64 - for Apple Silicon (M1/M2/M3)

echo "Building for Apple Silicon (arm64)..."
GOOS=darwin GOARCH=arm64 go build -mod=vendor -o "${OUTPUTPATH}/${OUTPUT}-arm64" .

echo "Building for Intel (amd64)..."
GOOS=darwin GOARCH=amd64 go build -mod=vendor -o "${OUTPUTPATH}/${OUTPUT}-amd64" .

if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo "Executable files:"
    echo "  ./output/${OUTPUT}-arm64"
    echo "  ./output/${OUTPUT}-amd64"
else
    echo "✗ Build failed"
    exit 1
fi
