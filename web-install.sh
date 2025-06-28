#!/bin/bash
# Morrigan Client Web Installer
# Usage: curl -sSL https://install.morrigan.ai | bash
# Or: wget -qO- https://install.morrigan.ai | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MORRIGAN_VERSION="latest"
MORRIGAN_REPO="MorriganAI/morrigan-client"
INSTALL_DIR="/usr/local/lib/morrigan"
BIN_DIR="/usr/local/bin"

# Platform detection
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $os in
        darwin)
            PLATFORM="macos"
            ;;
        linux)
            PLATFORM="linux"
            ;;
        *)
            echo -e "${RED}Error: Unsupported OS: $os${NC}"
            exit 1
            ;;
    esac
    
    case $arch in
        x86_64|amd64)
            ARCH="x64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $arch${NC}"
            exit 1
            ;;
    esac
    
    PACKAGE_NAME="morrigan-client-${PLATFORM}-${ARCH}.tar.gz"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check if running as root for system installation
    if [[ $EUID -eq 0 ]]; then
        INSTALL_MODE="system"
        echo -e "${GREEN}✓ Running with admin privileges (system installation)${NC}"
    else
        INSTALL_MODE="user"
        INSTALL_DIR="$HOME/.local/lib/morrigan"
        BIN_DIR="$HOME/.local/bin"
        echo -e "${YELLOW}⚠ Running as user (user installation to $HOME/.local)${NC}"
        
        # Create user bin directory if it doesn't exist
        mkdir -p "$BIN_DIR"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
            echo -e "${YELLOW}⚠ Add $BIN_DIR to your PATH:${NC}"
            echo "export PATH=\"$BIN_DIR:\$PATH\""
        fi
    fi
    
    # Check for required tools
    for tool in curl tar; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}Error: $tool is required but not installed${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✓ Prerequisites satisfied${NC}"
}

# Download and extract
download_morrigan() {
    echo -e "${BLUE}Downloading Morrigan Client ${MORRIGAN_VERSION}...${NC}"
    
    # Determine download URL
    if [ "$MORRIGAN_VERSION" = "latest" ]; then
        DOWNLOAD_URL="https://github.com/${MORRIGAN_REPO}/releases/latest/download/${PACKAGE_NAME}"
    else
        DOWNLOAD_URL="https://github.com/${MORRIGAN_REPO}/releases/download/v${MORRIGAN_VERSION}/${PACKAGE_NAME}"
    fi
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    # Download
    echo "Downloading from: $DOWNLOAD_URL"
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/$PACKAGE_NAME"; then
        echo -e "${RED}Error: Failed to download $PACKAGE_NAME${NC}"
        echo "Please check if the release exists at: $DOWNLOAD_URL"
        exit 1
    fi
    
    # Extract
    echo -e "${BLUE}Extracting...${NC}"
    tar -xzf "$TEMP_DIR/$PACKAGE_NAME" -C "$TEMP_DIR"
    
    # Find extracted directory
    EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*installer" | head -n1)
    if [ -z "$EXTRACTED_DIR" ]; then
        echo -e "${RED}Error: Could not find installer directory${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Downloaded and extracted successfully${NC}"
}

# Install binaries
install_binaries() {
    echo -e "${BLUE}Installing Morrigan Client...${NC}"
    
    # Create installation directory
    if [ "$INSTALL_MODE" = "system" ]; then
        sudo mkdir -p "$INSTALL_DIR"
        sudo cp -R "$EXTRACTED_DIR"/morrigan/* "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR"/morrigan*
    else
        mkdir -p "$INSTALL_DIR"
        cp -R "$EXTRACTED_DIR"/morrigan/* "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR"/morrigan*
    fi
    
    # Create symlinks
    echo -e "${BLUE}Creating command line tools...${NC}"
    if [ "$INSTALL_MODE" = "system" ]; then
        sudo ln -sf "$INSTALL_DIR/morrigan" "$BIN_DIR/morrigan"
        sudo ln -sf "$INSTALL_DIR/morrigan-service" "$BIN_DIR/morrigan-service"
        
        # Try to install GUI if available
        if [ -f "$INSTALL_DIR/morrigan-gui" ]; then
            sudo ln -sf "$INSTALL_DIR/morrigan-gui" "$BIN_DIR/morrigan-gui"
        fi
    else
        ln -sf "$INSTALL_DIR/morrigan" "$BIN_DIR/morrigan"
        ln -sf "$INSTALL_DIR/morrigan-service" "$BIN_DIR/morrigan-service"
        
        if [ -f "$INSTALL_DIR/morrigan-gui" ]; then
            ln -sf "$INSTALL_DIR/morrigan-gui" "$BIN_DIR/morrigan-gui"
        fi
    fi
    
    echo -e "${GREEN}✓ Binaries installed successfully${NC}"
}

# Configure application
configure_app() {
    echo -e "${BLUE}Setting up configuration...${NC}"
    
    # Determine config directory
    if [ "$INSTALL_MODE" = "system" ]; then
        CONFIG_DIR="/etc/morrigan"
        DATA_DIR="/var/lib/morrigan"
    else
        CONFIG_DIR="$HOME/.morrigan"
        DATA_DIR="$HOME/.morrigan"
    fi
    
    # Create directories
    if [ "$INSTALL_MODE" = "system" ]; then
        sudo mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    else
        mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    fi
    
    # Create default configuration if it doesn't exist
    ENV_FILE="$CONFIG_DIR/.env"
    if [ ! -f "$ENV_FILE" ]; then
        cat > /tmp/morrigan.env << 'EOF'
# Morrigan Client Configuration
ENV=production
API_URL=https://morrigan-poc-serverless.azurewebsites.net/api
API_KEY=your_api_key_here

# Replace API_KEY with your actual key from https://dashboard.morrigan.ai
# For development, change ENV to 'development'
EOF
        
        if [ "$INSTALL_MODE" = "system" ]; then
            sudo mv /tmp/morrigan.env "$ENV_FILE"
        else
            mv /tmp/morrigan.env "$ENV_FILE"
        fi
        
        echo -e "${YELLOW}⚠ Created configuration template at: $ENV_FILE${NC}"
        echo -e "${YELLOW}⚠ Please edit this file and set your API_KEY${NC}"
    fi
    
    echo -e "${GREEN}✓ Configuration setup complete${NC}"
}

# Install as service
install_service() {
    if [ "$INSTALL_MODE" != "system" ]; then
        echo -e "${YELLOW}⚠ Skipping service installation (user mode)${NC}"
        return
    fi
    
    echo -e "${BLUE}Installing system service...${NC}"
    
    if [ "$PLATFORM" = "macos" ]; then
        # macOS LaunchDaemon
        PLIST_FILE="/Library/LaunchDaemons/ai.morrigan.client.plist"
        cat > /tmp/morrigan.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.morrigan.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_DIR/morrigan-service</string>
        <string>--run-service</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/morrigan-client.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/morrigan-client-error.log</string>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
</dict>
</plist>
EOF
        sudo mv /tmp/morrigan.plist "$PLIST_FILE"
        sudo chmod 644 "$PLIST_FILE"
        echo -e "${GREEN}✓ macOS LaunchDaemon installed${NC}"
        
    elif [ "$PLATFORM" = "linux" ]; then
        # Linux systemd service
        SERVICE_FILE="/etc/systemd/system/morrigan-client.service"
        cat > /tmp/morrigan.service << EOF
[Unit]
Description=Morrigan LLM Monitoring Client
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=$BIN_DIR/morrigan-service --run-service
WorkingDirectory=$INSTALL_DIR
Restart=always
RestartSec=10
User=root
Environment=PATH=$BIN_DIR:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOF
        sudo mv /tmp/morrigan.service "$SERVICE_FILE"
        sudo chmod 644 "$SERVICE_FILE"
        sudo systemctl daemon-reload
        sudo systemctl enable morrigan-client.service
        echo -e "${GREEN}✓ Linux systemd service installed${NC}"
    fi
}

# Show completion message
show_completion() {
    echo
    echo -e "${GREEN}🎉 Morrigan Client installation completed!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Configure your API key:"
    if [ "$INSTALL_MODE" = "system" ]; then
        echo -e "   ${YELLOW}sudo nano /etc/morrigan/.env${NC}"
    else
        echo -e "   ${YELLOW}nano ~/.morrigan/.env${NC}"
    fi
    echo
    echo -e "2. Test the installation:"
    echo -e "   ${YELLOW}morrigan --config-check${NC}"
    echo -e "   ${YELLOW}morrigan --test-api${NC}"
    echo
    echo -e "3. Start monitoring:"
    if [ "$INSTALL_MODE" = "system" ]; then
        if [ "$PLATFORM" = "macos" ]; then
            echo -e "   ${YELLOW}sudo launchctl load /Library/LaunchDaemons/ai.morrigan.client.plist${NC}"
        else
            echo -e "   ${YELLOW}sudo systemctl start morrigan-client${NC}"
        fi
    else
        echo -e "   ${YELLOW}morrigan-service --foreground${NC}"
    fi
    echo
    echo -e "4. Or use the GUI (if available):"
    echo -e "   ${YELLOW}morrigan-gui${NC}"
    echo
    echo -e "${BLUE}Documentation:${NC} https://docs.morrigan.ai"
    echo -e "${BLUE}Support:${NC} https://github.com/MorriganAI/morrigan-client/issues"
}

# Main installation flow
main() {
    echo -e "${BLUE}Morrigan Client Web Installer${NC}"
    echo -e "${BLUE}=============================${NC}"
    echo
    
    detect_platform
    echo -e "${BLUE}Detected platform: $PLATFORM-$ARCH${NC}"
    echo
    
    check_prerequisites
    download_morrigan
    install_binaries
    configure_app
    install_service
    show_completion
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            MORRIGAN_VERSION="$2"
            shift 2
            ;;
        --user)
            INSTALL_MODE="user"
            shift
            ;;
        --system)
            INSTALL_MODE="system"
            shift
            ;;
        --help)
            echo "Morrigan Client Web Installer"
            echo
            echo "Usage: curl -sSL https://install.morrigan.ai | bash"
            echo "       curl -sSL https://install.morrigan.ai | bash -s -- [options]"
            echo
            echo "Options:"
            echo "  --version VERSION   Install specific version (default: latest)"
            echo "  --user             Force user installation"
            echo "  --system           Force system installation (requires sudo)"
            echo "  --help             Show this help"
            echo
            echo "Examples:"
            echo "  curl -sSL https://install.morrigan.ai | bash"
            echo "  curl -sSL https://install.morrigan.ai | bash -s -- --version 1.0.0"
            echo "  curl -sSL https://install.morrigan.ai | bash -s -- --user"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Run main installation
main
