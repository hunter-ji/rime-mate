#!/bin/bash

# Build script - Compile for macOS executable

echo "Building rime_mate..."

# Set output filename
OUTPUTPATH="./output"
OUTPUT="rime_mate"

# Build for macOS executable
# GOOS=darwin GOARCH=amd64 - for Intel Mac
# GOOS=darwin GOARCH=arm64 - for Apple Silicon (M1/M2/M3)

# Detect current Mac architecture and build
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo "Detected Apple Silicon, building for arm64..."
    GOOS=darwin GOARCH=arm64 go build -mod=vendor -o ${OUTPUTPATH}/${OUTPUT} main.go
else
    echo "Detected Intel architecture, building for amd64..."
    GOOS=darwin GOARCH=amd64 go build -mod=vendor -o ${OUTPUTPATH}/${OUTPUT} main.go
fi

if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo "Executable file: ./${OUTPUT}"
    echo ""
    echo "Run the program:"
    echo "  ./${OUTPUT}"
else
    echo "✗ Build failed"
    exit 1
fi
