#!/bin/bash
# Auto-download script for Unix systems

set -e

echo "Morrigan LLM Monitor - Auto Installer"
echo "===================================="

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $OS in
    darwin) PLATFORM="darwin" ;;
    linux) PLATFORM="linux" ;;
    *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

case $ARCH in
    x86_64|amd64) ARCH="x86_64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

if [ "$PLATFORM" = "darwin" ]; then
    FILENAME="morrigan-installer-darwin-arm64.zip"
else
    FILENAME="morrigan-installer-linux-x86_64.zip"
fi

URL="https://github.com/john-morrigan/morrigan-releases/releases/latest/download/$FILENAME"

echo "Downloading $FILENAME..."
curl -L -o "$FILENAME" "$URL"

echo "Extracting..."
unzip -q "$FILENAME"

echo "Starting installer..."
echo "You may be prompted for sudo password..."
sudo ./MorriganInstaller

echo "Installation complete!"
