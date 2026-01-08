#!/bin/bash

# Build script - Compile for macOS executable + Linux executable
echo "Building rime-mate..."

# Set output filename
OUTPUTPATH="./output"
OUTPUT="rime-mate"

mkdir -p "${OUTPUTPATH}"

# Build for macOS executable
# GOOS=darwin GOARCH=amd64 - for Intel Mac
# GOOS=darwin GOARCH=arm64 - for Apple Silicon (M1/M2/M3)

echo "Building for Intel (amd64)..."
GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -mod=vendor -o "${OUTPUTPATH}/${OUTPUT}-darwin-amd64" .

echo "Building for Apple Silicon (arm64)..."
GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -mod=vendor -o "${OUTPUTPATH}/${OUTPUT}-darwin-arm64" .

# Build for Linux executable
# GOOS=linux GOARCH=amd64 - for x86_64 Linux
# GOOS=linux GOARCH=arm64 - for ARM64 Linux (aarch64)

echo "Building for Linux x86_64 (amd64)..."
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -mod=vendor -o "${OUTPUTPATH}/${OUTPUT}-linux-amd64" .

echo "Building for Linux ARM64 (aarch64)..."
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -mod=vendor -o "${OUTPUTPATH}/${OUTPUT}-linux-arm64" .



if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo "Executable files:"
    echo "  ./output/${OUTPUT}-darwin-arm64"
    echo "  ./output/${OUTPUT}-darwin-amd64"
    echo "  ./output/${OUTPUT}-linux-arm64"
    echo "  ./output/${OUTPUT}-linux-amd64"
else
    echo "✗ Build failed"
    exit 1
fi
