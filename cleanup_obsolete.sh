#!/bin/bash
# Cleanup obsolete files after switching to native .NET approach

echo "🧹 Cleaning up obsolete Docker/Wine files..."

# Files to remove
OBSOLETE_FILES=(
    "Dockerfile.windows"
    "Dockerfile.wine" 
    "Dockerfile.colima"
    "build_msi_docker.sh"
    "build_wine_msi.py"
    "requirements-docker.txt"
    "setup_colima_build.sh"
    "build_msi_macos.py"
)

# Optional files (ask user)
OPTIONAL_FILES=(
    "build_complete.py"
)

# Count of files to remove
REMOVED_COUNT=0

echo "Removing Docker/Wine related files:"
for file in "${OBSOLETE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ❌ Removing: $file"
        rm "$file"
        ((REMOVED_COUNT++))
    else
        echo "  ⚪ Not found: $file"
    fi
done

echo ""
echo "Optional files (complex automation):"
for file in "${OPTIONAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        read -p "  🤔 Remove $file? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "  ❌ Removing: $file"
            rm "$file"
            ((REMOVED_COUNT++))
        else
            echo "  ✅ Keeping: $file"
        fi
    fi
done

echo ""
echo "📋 Current files structure:"
echo "=========================="
echo "✅ Essential files:"
echo "  - build_msi_native.sh (main build script)"
echo "  - setup_macos.sh (setup verification)"
echo "  - morrigan-installer/installer/msi/build_msi.py (core builder)"
echo "  - morrigan-installer/installer/msi/wix_installer.wxs (WiX template)"
echo ""
echo "✅ Supporting files:"
echo "  - MSI_BUILD_GUIDE.md (documentation)"
echo "  - morrigan-installer/config/ (configuration)"
echo "  - morrigan-installer/resources/ (icons, images, licenses)"
echo "  - morrigan-installer/templates/ (config templates)"

if [ -f "index.html" ] || [ -f "install.py" ]; then
    echo ""
    echo "❓ Web installer files detected:"
    if [ -f "index.html" ]; then echo "  - index.html"; fi
    if [ -f "install.py" ]; then echo "  - install.py"; fi
    if [ -f "web-install.sh" ]; then echo "  - web-install.sh"; fi
    if [ -f "verify.sh" ]; then echo "  - verify.sh"; fi
    echo "  (Keep these if you want web-based installation)"
fi

echo ""
echo "🎉 Cleanup complete! Removed $REMOVED_COUNT files."
echo ""
echo "💡 Next steps:"
echo "  1. Run: ./setup_macos.sh (one-time setup)"
echo "  2. Build: ./build_msi_native.sh"
echo ""

# Check if git repository and offer to commit changes
if [ -d ".git" ]; then
    echo "📝 Git repository detected."
    read -p "🤔 Commit cleanup changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        git commit -m "Clean up obsolete Docker/Wine files - switch to native .NET approach

- Removed Docker-related files (Dockerfile.*, build_msi_docker.sh, etc.)
- Removed Wine-based approach files
- Kept native macOS .NET solution (build_msi_native.sh)
- Streamlined to essential files only"
        
        echo "✅ Changes committed to git"
    fi
fi
