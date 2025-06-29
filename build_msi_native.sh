#!/bin/bash
# Native macOS MSI Builder using .NET Core WiX
# No Docker, no Wine - pure macOS + .NET solution

set -e

echo "🍎 Native macOS MSI Builder for Morrigan"
echo "========================================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS"
    exit 1
fi

# Check if .NET is installed
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET not found!"
    echo "💡 Install .NET:"
    echo "   Download from: https://dotnet.microsoft.com/download"
    echo "   Or use Homebrew: brew install dotnet"
    exit 1
fi

# Show .NET version
DOTNET_VERSION=$(dotnet --version)
echo "✅ .NET version: $DOTNET_VERSION"

# Check if WiX v4 is installed as global tool
echo "🔍 Checking for WiX v4..."
if dotnet tool list -g | grep -q "wix"; then
    WIX_VERSION=$(dotnet tool list -g | grep wix | awk '{print $2}')
    echo "✅ WiX v4 found: $WIX_VERSION"
else
    echo "📦 Installing WiX v4 as .NET global tool..."
    dotnet tool install --global wix
    
    if [ $? -eq 0 ]; then
        echo "✅ WiX v4 installed successfully!"
    else
        echo "❌ Failed to install WiX v4"
        exit 1
    fi
fi

# Verify WiX works
echo "🧪 Testing WiX installation..."
if wix --version >/dev/null 2>&1; then
    WIX_VERSION=$(wix --version)
    echo "✅ WiX is working: $WIX_VERSION"
else
    echo "❌ WiX command not working"
    echo "💡 Try: export PATH=\"$HOME/.dotnet/tools:$PATH\""
    echo "💡 Or restart your terminal"
    exit 1
fi

# Build Morrigan executable if needed
MORRIGAN_DIR="../morrigan"
MORRIGAN_DIST="$MORRIGAN_DIR/dist"

if [ ! -f "$MORRIGAN_DIST/morrigan" ] && [ ! -f "$MORRIGAN_DIST/morrigan.exe" ]; then
    echo "🔨 Building Morrigan executable..."
    cd "$MORRIGAN_DIR"
    python3 build_standalone.py
    cd - > /dev/null
fi

# Check for executable
if [ -f "$MORRIGAN_DIST/morrigan" ]; then
    echo "✅ Found Morrigan executable (Unix format)"
    MORRIGAN_EXE="$MORRIGAN_DIST/morrigan"
elif [ -f "$MORRIGAN_DIST/morrigan.exe" ]; then
    echo "✅ Found Morrigan executable (Windows format)"
    MORRIGAN_EXE="$MORRIGAN_DIST/morrigan.exe"
else
    echo "❌ Morrigan executable not found!"
    echo "💡 Build it first: cd $MORRIGAN_DIR && python3 build_standalone.py"
    exit 1
fi

# Run the Python MSI builder
echo "🔨 Building MSI installer..."
echo ""

cd morrigan-installer/installer/msi

python3 build_msi.py --build-dir "$MORRIGAN_DIST"
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! MSI installer built on macOS!"
    
    # Show output files
    if [ -f "dist/morrigan_installer.msi" ]; then
        FILE_SIZE=$(du -h "dist/morrigan_installer.msi" | cut -f1)
        echo "📦 MSI file: dist/morrigan_installer.msi ($FILE_SIZE)"
        
        # Copy to main project dist
        mkdir -p "../../../dist"
        cp "dist/morrigan_installer.msi" "../../../dist/"
        echo "✅ Copied to: ../../../dist/morrigan_installer.msi"
    fi
    
    echo ""
    echo "💡 Next steps:"
    echo "   1. Transfer MSI to Windows machine for testing"
    echo "   2. Install: msiexec /i morrigan_installer.msi"
    echo "   3. Distribute as needed"
    
else
    echo "❌ MSI build failed!"
    echo ""
    echo "🛠️ Troubleshooting:"
    echo "   1. Check .NET: dotnet --version"
    echo "   2. Check WiX: wix --version"
    echo "   3. Update PATH: export PATH=\"$HOME/.dotnet/tools:$PATH\""
    echo "   4. Reinstall WiX: dotnet tool uninstall -g wix && dotnet tool install -g wix"
fi

exit $BUILD_EXIT_CODE
