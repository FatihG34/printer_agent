#!/bin/bash

echo "Building Alpidi Printer Agent using Docker..."

# Build Docker image
docker build -f Dockerfile.windows-build -t alpidi-printer-agent-builder .

# Create dist directory
mkdir -p dist

# Run container and copy output
docker run --rm -v $(pwd)/dist:/dist alpidi-printer-agent-builder

echo ""
echo "Build completed! Check dist/ folder for output files."
echo ""
ls -la dist/