# Morrigan MSI Installer Guide

## Overview
This guide explains how to use WiX Toolset to build MSI installers for your Morrigan application.

## Prerequisites

### 1. Install WiX Toolset

#### Option A: WiX Toolset v4 (Recommended)
```bash
# Install via .NET CLI (cross-platform)
dotnet tool install --global wix

# Verify installation
wix --version
```

#### Option B: WiX Toolset v3
- Download from: https://wixtoolset.org/releases/
- Install the MSI package
- Add to PATH: `C:\Program Files (x86)\WiX Toolset v3.11\bin`

#### Option C: Package Managers
```bash
# Chocolatey
choco install wixtoolset

# Winget
winget install Microsoft.WiXToolset
```

### 2. Build Dependencies
- Python 3.8+
- PyInstaller (for executable creation)
- Windows OS (for MSI building)

## Quick Start

### 1. Build Everything (Automated)
```bash
# From the morrigan-installer directory
python build_complete.py --clean

# With code signing
python build_complete.py --clean --sign
```

### 2. Build Just the MSI
```bash
# First, build the Morrigan executable
cd ../morrigan
python build_standalone.py

# Then build the MSI
cd ../morrigan-installer/morrigan-installer/installer/msi
python build_msi.py
```

### 3. Manual WiX Commands
```bash
# Compile WiX source to object file
candle.exe wix_installer.wxs

# Link object file to create MSI
light.exe wix_installer.wixobj -o morrigan_installer.msi

# Or with WiX v4
wix build wix_installer.wxs -o morrigan_installer.msi
```

## Project Structure

```
morrigan-installer/
├── build_complete.py              # Complete build automation
├── morrigan-installer/
│   ├── config/
│   │   ├── installer_config.json  # Installer settings
│   │   └── signing_config.json    # Code signing config
│   ├── installer/
│   │   └── msi/
│   │       ├── build_msi.py       # Enhanced MSI builder
│   │       ├── wix_installer.wxs  # WiX template
│   │       └── dist/              # Output directory
│   ├── templates/
│   │   ├── default_config.json    # Default app config
│   │   └── .env.template          # Environment template
│   └── resources/
│       ├── icons/                 # Application icons
│       ├── images/                # Installer images
│       └── license/               # License files
```

## Configuration

### Installer Configuration (`config/installer_config.json`)
```json
{
    "product_name": "Morrigan Client",
    "version": "1.0.0",
    "manufacturer": "Morrigan AI",
    "upgrade_code": "YOUR-UPGRADE-CODE-HERE",
    "install_directory": "C:\\Program Files\\Morrigan Client"
}
```

### WiX Template Features
The `wix_installer.wxs` template includes:

- **Professional UI**: Complete installation wizard
- **Start Menu Shortcuts**: Automatic shortcut creation
- **Desktop Shortcut**: Optional desktop icon
- **File Associations**: Register .morrigan config files
- **Registry Entries**: Application registration
- **Upgrade Logic**: Handles version upgrades
- **Firewall Exception**: Optional network access
- **Windows Service**: Optional service installation
- **Uninstall Support**: Clean removal

## Advanced Usage

### Custom Build Options

```bash
# Development build (faster, less validation)
python build_complete.py --dev

# Clean build with signing
python build_complete.py --clean --sign

# Specific build directory
python build_msi.py --build-dir "C:\path\to\morrigan\dist"
```

### Code Signing

1. Configure signing in `config/signing_config.json`:
```json
{
    "certificate_path": "path/to/certificate.pfx",
    "certificate_password": "password",
    "timestamp_url": "http://timestamp.digicert.com"
}
```

2. Build with signing:
```bash
python build_complete.py --sign
```

### Custom WiX Features

#### Add Registry Entries
```xml
<RegistryKey Root="HKLM" Key="SOFTWARE\Morrigan AI\Morrigan">
    <RegistryValue Name="CustomSetting" Type="string" Value="CustomValue" />
</RegistryKey>
```

#### Add File Associations
```xml
<ProgId Id="Morrigan.Config" Description="Morrigan Configuration">
    <Extension Id="morrigan" ContentType="application/json">
        <Verb Id="open" Command="Open" Argument='"%%1"' />
    </Extension>
</ProgId>
```

#### Windows Service Installation
```xml
<ServiceInstall Id="MorriganServiceInstall"
                Type="ownProcess"
                Name="MorriganService"
                DisplayName="Morrigan LLM Monitor"
                Start="auto"
                Account="LocalSystem" />
```

## Troubleshooting

### Common Issues

1. **WiX Not Found**
   - Install WiX Toolset
   - Check PATH environment variable
   - Use `wix --version` to verify

2. **GUID Errors**
   - Run the enhanced build script to auto-generate GUIDs
   - Use online GUID generator for manual replacement

3. **File Path Issues**
   - Use absolute paths in WiX template
   - Check source file existence
   - Verify build output directory

4. **MSI Validation Errors**
   - Use Windows SDK tools for validation
   - Check component GUIDs are unique
   - Validate registry entries

### Build Verification

```bash
# Test MSI installation
msiexec /i morrigan_installer.msi /l*v install.log

# Test MSI uninstallation
msiexec /x morrigan_installer.msi /l*v uninstall.log

# Silent installation
msiexec /i morrigan_installer.msi /quiet
```

## Best Practices

1. **Version Management**
   - Use semantic versioning (1.0.0)
   - Update upgrade codes for major versions
   - Test upgrade scenarios

2. **Component Design**
   - One file per component
   - Unique GUIDs for each component
   - Logical feature organization

3. **Testing**
   - Test on clean Windows VMs
   - Verify upgrade and uninstall scenarios
   - Test different user privilege levels

4. **Distribution**
   - Code sign for security
   - Test on multiple Windows versions
   - Provide installation documentation

## Resources

- [WiX Toolset Documentation](https://wixtoolset.org/documentation/)
- [WiX Tutorial](https://www.firegiant.com/wix/tutorial/)
- [MSI Best Practices](https://docs.microsoft.com/en-us/windows/win32/msi/installation-package-authoring)
- [Code Signing Guide](https://docs.microsoft.com/en-us/windows/win32/appxpkg/signing-a-package)
