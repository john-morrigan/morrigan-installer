#!/bin/bash
# Morrigan Client Installation Verification Script
# Usage: curl -sSL https://install.morrigan.ai/verify | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Morrigan Client Installation Verification${NC}"
echo "=============================================="

# Check if morrigan command exists
echo -n "Checking morrigan command... "
if command -v morrigan >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Found${NC}"
    MORRIGAN_PATH=$(which morrigan)
    echo "   Location: $MORRIGAN_PATH"
else
    echo -e "${RED}✗ Not found${NC}"
    echo -e "${YELLOW}The 'morrigan' command is not in your PATH.${NC}"
    echo "Try running: export PATH=\"/usr/local/bin:\$PATH\""
    echo "Or reinstall with: curl -sSL https://install.morrigan.ai | bash"
    exit 1
fi

echo

# Check service status
echo -n "Checking service status... "
if morrigan status >/dev/null 2>&1; then
    STATUS=$(morrigan status 2>/dev/null || echo "unknown")
    if echo "$STATUS" | grep -q "running\|active"; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${YELLOW}⚠ Not running${NC}"
        echo "   Status: $STATUS"
        echo "   Try: morrigan start"
    fi
else
    echo -e "${RED}✗ Error checking status${NC}"
    echo "   Try: morrigan start"
fi

echo

# Check configuration
echo -n "Checking configuration... "
CONFIG_PATHS=(
    "$HOME/.config/morrigan/config.json"
    "/etc/morrigan/config.json"
    "/usr/local/etc/morrigan/config.json"
)

CONFIG_FOUND=false
for path in "${CONFIG_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        echo -e "${GREEN}✓ Found${NC}"
        echo "   Location: $path"
        CONFIG_FOUND=true
        break
    fi
done

if [[ "$CONFIG_FOUND" == false ]]; then
    echo -e "${YELLOW}⚠ Not found${NC}"
    echo "   Configuration will use defaults"
fi

echo

# Check logs
echo -n "Checking logs... "
if morrigan logs --tail 1 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
    echo "   Recent activity:"
    morrigan logs --tail 3 2>/dev/null | sed 's/^/   /' || echo "   No recent logs"
else
    echo -e "${YELLOW}⚠ No logs available${NC}"
    echo "   Service may not be running or just started"
fi

echo

# Platform-specific checks
case "$(uname -s)" in
    Darwin)
        echo -n "Checking macOS LaunchDaemon... "
        PLIST_PATH="/Library/LaunchDaemons/com.morrigan.client.plist"
        if [[ -f "$PLIST_PATH" ]]; then
            echo -e "${GREEN}✓ Installed${NC}"
            echo "   Location: $PLIST_PATH"
            
            # Check if loaded
            if launchctl list | grep -q "com.morrigan.client"; then
                echo -e "   Status: ${GREEN}Loaded${NC}"
            else
                echo -e "   Status: ${YELLOW}Not loaded${NC}"
                echo "   Try: sudo launchctl load $PLIST_PATH"
            fi
        else
            echo -e "${RED}✗ Not found${NC}"
        fi
        ;;
    Linux)
        echo -n "Checking systemd service... "
        if systemctl is-enabled morrigan >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Enabled${NC}"
            if systemctl is-active morrigan >/dev/null 2>&1; then
                echo -e "   Status: ${GREEN}Active${NC}"
            else
                echo -e "   Status: ${YELLOW}Inactive${NC}"
                echo "   Try: sudo systemctl start morrigan"
            fi
        else
            echo -e "${YELLOW}⚠ Not enabled${NC}"
            echo "   Try: sudo systemctl enable morrigan"
        fi
        ;;
esac

echo

# Check network connectivity
echo -n "Checking network connectivity... "
if curl -s --max-time 5 https://api.morrigan.ai/health >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
elif curl -s --max-time 5 https://google.com >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Internet OK, Morrigan API unreachable${NC}"
    echo "   This is normal if the service isn't deployed yet"
else
    echo -e "${RED}✗ No internet connection${NC}"
fi

echo

# Summary
echo -e "${BLUE}📊 Summary${NC}"
echo "==========="

# Overall health check
ISSUES=0

if ! command -v morrigan >/dev/null 2>&1; then
    ISSUES=$((ISSUES + 1))
fi

if ! morrigan status >/dev/null 2>&1 || ! morrigan status 2>/dev/null | grep -q "running\|active"; then
    ISSUES=$((ISSUES + 1))
fi

if [[ $ISSUES -eq 0 ]]; then
    echo -e "${GREEN}✅ Morrigan is properly installed and running!${NC}"
    echo
    echo "🎯 Next steps:"
    echo "   • The service will automatically monitor LLM usage"
    echo "   • View status anytime with: morrigan status"
    echo "   • Check logs with: morrigan logs"
    echo "   • Stop/start with: morrigan stop/start"
    echo
    echo "📱 System tray app should be available (GUI systems)"
    echo "📚 Documentation: https://docs.morrigan.ai"
elif [[ $ISSUES -eq 1 ]]; then
    echo -e "${YELLOW}⚠ Morrigan is installed with minor issues${NC}"
    echo "   Most functionality should work normally"
    echo "   Review the warnings above if needed"
else
    echo -e "${RED}❌ Morrigan installation has issues${NC}"
    echo "   Please review the errors above"
    echo "   Try reinstalling: curl -sSL https://install.morrigan.ai | bash"
    echo "   Or get help: https://github.com/MorriganAI/morrigan-client/issues"
fi

echo
echo "🔧 Useful commands:"
echo "   morrigan --help     - Show all available commands"
echo "   morrigan version    - Show version information"
echo "   morrigan config     - Show current configuration"
echo "   morrigan uninstall  - Remove Morrigan completely"
