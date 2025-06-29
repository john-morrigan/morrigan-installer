#!/bin/bash
# Setup verification and WiX installation for macOS

echo "🔧 Morrigan MSI Builder Setup for macOS"
echo "======================================="

# Function to check command availability
check_command() {
    if command -v "$1" &> /dev/null; then
        echo "✅ $1 is available"
        return 0
    else
        echo "❌ $1 not found"
        return 1
    fi
}

# Function to install via Homebrew
install_via_brew() {
    if command -v brew &> /dev/null; then
        echo "🍺 Installing $1 via Homebrew..."
        brew install "$1"
    else
        echo "❌ Homebrew not found. Please install manually."
        return 1
    fi
}

echo "🔍 Checking prerequisites..."

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo "🍎 macOS version: $MACOS_VERSION"

# Check architecture
ARCH=$(uname -m)
echo "🏗️ Architecture: $ARCH"

# Check Python
if check_command python3; then
    PYTHON_VERSION=$(python3 --version)
    echo "   Version: $PYTHON_VERSION"
else
    echo "💡 Install Python: brew install python"
    exit 1
fi

# Check .NET
echo ""
echo "🔍 Checking .NET Core..."
if check_command dotnet; then
    DOTNET_VERSION=$(dotnet --version)
    echo "   Version: $DOTNET_VERSION"
    
    # Check if version is compatible (6.0+)
    MAJOR_VERSION=$(echo $DOTNET_VERSION | cut -d. -f1)
    if [ "$MAJOR_VERSION" -ge 6 ]; then
        echo "   ✅ .NET version compatible with WiX v4"
    else
        echo "   ⚠️ .NET $DOTNET_VERSION may not support WiX v4"
        echo "   💡 Consider upgrading to .NET 6.0+"
    fi
else
    echo "❌ .NET not found!"
    echo ""
    echo "📦 Installation options:"
    echo "1. Official installer: https://dotnet.microsoft.com/download"
    echo "2. Homebrew: brew install dotnet"
    echo ""
    read -p "Install .NET via Homebrew? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_via_brew dotnet
    else
        echo "Please install .NET manually and re-run this script"
        exit 1
    fi
fi

# Check and install WiX v4
echo ""
echo "🔍 Checking WiX Toolset..."

# Ensure .NET tools path is in PATH
DOTNET_TOOLS_PATH="$HOME/.dotnet/tools"
if [[ ":$PATH:" != *":$DOTNET_TOOLS_PATH:"* ]]; then
    echo "🔧 Adding .NET tools to PATH..."
    export PATH="$DOTNET_TOOLS_PATH:$PATH"
    
    # Add to shell profile
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "/.dotnet/tools" "$HOME/.zshrc"; then
            echo 'export PATH="$HOME/.dotnet/tools:$PATH"' >> "$HOME/.zshrc"
            echo "✅ Added to ~/.zshrc"
        fi
    elif [ -f "$HOME/.bash_profile" ]; then
        if ! grep -q "/.dotnet/tools" "$HOME/.bash_profile"; then
            echo 'export PATH="$HOME/.dotnet/tools:$PATH"' >> "$HOME/.bash_profile"
            echo "✅ Added to ~/.bash_profile"
        fi
    fi
fi

# Check if WiX is installed
if dotnet tool list -g | grep -q "wix"; then
    WIX_VERSION=$(dotnet tool list -g | grep wix | awk '{print $2}')
    echo "✅ WiX v4 already installed: $WIX_VERSION"
else
    echo "📦 Installing WiX v4..."
    dotnet tool install --global wix
    
    if [ $? -eq 0 ]; then
        echo "✅ WiX v4 installed successfully!"
    else
        echo "❌ Failed to install WiX v4"
        exit 1
    fi
fi

# Test WiX command
echo ""
echo "🧪 Testing WiX installation..."
if wix --version >/dev/null 2>&1; then
    WIX_VERSION=$(wix --version)
    echo "✅ WiX is working: $WIX_VERSION"
else
    echo "❌ WiX command not working"
    echo "💡 You may need to restart your terminal or run:"
    echo "   export PATH=\"$HOME/.dotnet/tools:\$PATH\""
fi

# Check for required Python packages
echo ""
echo "🔍 Checking Python packages..."
REQUIRED_PACKAGES=("uuid" "pathlib")

for package in "${REQUIRED_PACKAGES[@]}"; do
    if python3 -c "import $package" 2>/dev/null; then
        echo "✅ $package available"
    else
        echo "❌ $package not found"
        echo "📦 Installing $package..."
        python3 -m pip install "$package"
    fi
done

# Summary
echo ""
echo "📋 Setup Summary:"
echo "=================="
echo "🍎 macOS: $MACOS_VERSION ($ARCH)"
echo "🐍 Python: $(python3 --version)"
echo "🔷 .NET: $(dotnet --version)"

if wix --version >/dev/null 2>&1; then
    echo "⚒️ WiX: $(wix --version)"
    echo ""
    echo "🎉 ALL PREREQUISITES READY!"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Run: ./build_msi_native.sh"
    echo "   2. Or use Python directly: cd morrigan-installer/installer/msi && python3 build_msi.py"
else
    echo "❌ WiX: Not working"
    echo ""
    echo "⚠️ SETUP INCOMPLETE"
    echo "💡 Restart your terminal and try again"
fi

echo ""
echo "🔧 Troubleshooting:"
echo "   - Restart terminal after .NET/WiX installation"
echo "   - Check PATH: echo \$PATH | grep dotnet"
echo "   - Reinstall WiX: dotnet tool uninstall -g wix && dotnet tool install -g wix"
