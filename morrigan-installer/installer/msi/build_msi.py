#!/usr/bin/env python3
"""
Enhanced MSI Builder using WiX Toolset for Morrigan Application

This script handles:
- WiX Toolset detection and installation guidance
- Dynamic GUID generation
- Template preprocessing
- Cross-platform build support
- Error handling and validation
"""

import os
import subprocess
import sys
import json
import uuid
import shutil
from pathlib import Path
from typing import Dict, List, Optional

class WiXBuilder:
    """Enhanced WiX MSI builder for Morrigan"""
    
    def __init__(self, config_path: Optional[str] = None):
        self.script_dir = Path(__file__).parent
        self.config_path = config_path or self.script_dir.parent.parent / "config" / "installer_config.json"
        self.config = self._load_config()
        self.wix_paths = self._detect_wix_paths()
        
    def _load_config(self) -> Dict:
        """Load installer configuration"""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Warning: Could not load config from {self.config_path}: {e}")
            return self._get_default_config()
    
    def _get_default_config(self) -> Dict:
        """Default configuration if config file is missing"""
        return {
            "product_name": "Morrigan Client",
            "version": "0.1.0",
            "manufacturer": "Morrigan AI",
            "upgrade_code": str(uuid.uuid4()),
            "output_directory": "dist",
            "icon_path": "resources/icons/morrigan.ico",
            "license_path": "resources/license/LICENSE.rtf"
        }
    
    def _detect_wix_paths(self) -> List[str]:
        """Detect possible WiX installation paths (cross-platform)"""
        possible_paths = []
        
        # Windows paths (if running on Windows)
        if os.name == 'nt':
            possible_paths.extend([
                r"C:\Program Files (x86)\WiX Toolset v3.11\bin",
                r"C:\Program Files (x86)\WiX Toolset v3.14\bin", 
                r"C:\Program Files\WiX Toolset v4.0\bin",
                r"C:\Tools\wix\bin",
            ])
        
        # Cross-platform .NET tool paths for WiX v4
        dotnet_tools_paths = [
            os.path.expanduser("~/.dotnet/tools"),
            "/usr/local/share/dotnet/tools",
            "/usr/share/dotnet/tools"
        ]
        possible_paths.extend(dotnet_tools_paths)
        
        valid_paths = []
        for path in possible_paths:
            if os.path.exists(path):
                # Check for candle.exe (v3) or wix/wix.exe (v4)
                wix_exe = os.path.join(path, "wix.exe") if os.name == 'nt' else os.path.join(path, "wix")
                candle_exe = os.path.join(path, "candle.exe")
                
                if os.path.exists(wix_exe) or os.path.exists(candle_exe):
                    valid_paths.append(path)
        
        return valid_paths
    
    def check_wix_installation(self) -> bool:
        """Check if WiX is properly installed (cross-platform)"""
        
        # First, try to detect installed WiX
        if self.wix_paths:
            print(f"✅ WiX Toolset found at: {self.wix_paths[0]}")
            return True
        
        # If not found, check if dotnet is available and try to install WiX v4
        if shutil.which("dotnet"):
            print("� WiX not found, but .NET detected. Checking for WiX v4...")
            
            # Check if WiX is available as a dotnet tool
            try:
                result = subprocess.run(["dotnet", "tool", "list", "-g"], 
                                      capture_output=True, text=True, timeout=30)
                if "wix" in result.stdout.lower():
                    print("✅ WiX v4 found as .NET global tool")
                    # Update paths to include dotnet tools
                    self.wix_paths = [os.path.expanduser("~/.dotnet/tools")]
                    return True
                else:
                    print("📦 Installing WiX v4 as .NET global tool...")
                    install_result = subprocess.run(["dotnet", "tool", "install", "--global", "wix"], 
                                                   capture_output=True, text=True, timeout=60)
                    if install_result.returncode == 0:
                        print("✅ WiX v4 installed successfully!")
                        self.wix_paths = [os.path.expanduser("~/.dotnet/tools")]
                        return True
                    else:
                        print(f"❌ Failed to install WiX v4: {install_result.stderr}")
            except subprocess.TimeoutExpired:
                print("⏰ Timeout checking/installing WiX")
            except Exception as e:
                print(f"❌ Error checking .NET tools: {e}")
        
        print("❌ WiX Toolset not found!")
        print("\n📦 Installation Options:")
        print("1. WiX v4 (.NET): dotnet tool install --global wix")
        print("2. WiX v3 (Windows): Download from https://wixtoolset.org/releases/")
        print("3. Chocolatey (Windows): choco install wixtoolset")
        return False
    
    def generate_guids(self) -> Dict[str, str]:
        """Generate required GUIDs for WiX installer"""
        return {
            "upgrade_code": str(uuid.uuid4()).upper(),
            "product_code": str(uuid.uuid4()).upper(),
            "component_main": str(uuid.uuid4()).upper(),
            "component_config": str(uuid.uuid4()).upper(),
            "component_license": str(uuid.uuid4()).upper(),
            "component_resources": str(uuid.uuid4()).upper()
        }
    
    def prepare_source_files(self, morrigan_build_dir: str) -> bool:
        """Prepare source files for packaging"""
        build_path = Path(morrigan_build_dir)
        if not build_path.exists():
            print(f"❌ Morrigan build directory not found: {build_path}")
            print("💡 Run the following first:")
            print("   cd ../../../morrigan && python build_standalone.py")
            return False
        
        # Check for executable
        exe_candidates = [
            build_path / "morrigan.exe",
            build_path / "morrigan",
            build_path / "dist" / "morrigan.exe",
            build_path / "dist" / "morrigan"
        ]
        
        for exe_path in exe_candidates:
            if exe_path.exists():
                print(f"✅ Found executable: {exe_path}")
                return True
        
        print("❌ No Morrigan executable found in build directory")
        return False
    
    def build_msi(self, morrigan_build_dir: str = None) -> bool:
        """Build MSI installer using WiX"""
        
        # Default to looking for built morrigan
        if not morrigan_build_dir:
            morrigan_build_dir = str(self.script_dir.parent.parent.parent.parent / "morrigan" / "dist")
        
        print("🔨 Building Morrigan MSI Installer...")
        print("=" * 50)
        
        # Check prerequisites
        if not self.check_wix_installation():
            return False
        
        if not self.prepare_source_files(morrigan_build_dir):
            return False
        
        # Setup environment
        wix_bin = self.wix_paths[0]
        
        # Add WiX to PATH (different handling for cross-platform)
        if os.name == 'nt':
            os.environ["PATH"] = wix_bin + os.pathsep + os.environ.get("PATH", "")
        else:
            # On Unix systems, dotnet tools should already be in PATH
            # but ensure the tools directory is included
            current_path = os.environ.get("PATH", "")
            if wix_bin not in current_path:
                os.environ["PATH"] = wix_bin + os.pathsep + current_path
        
        # File paths
        wix_template = self.script_dir / "wix_installer.wxs"
        wix_processed = self.script_dir / "wix_installer_processed.wxs"
        wixobj_file = self.script_dir / "morrigan_installer.wixobj"
        msi_output = self.script_dir / "dist" / "morrigan_installer.msi"
        
        # Create output directory
        msi_output.parent.mkdir(exist_ok=True)
        
        try:
            # Generate GUIDs and process template
            guids = self.generate_guids()
            self._process_wix_template(wix_template, wix_processed, guids, morrigan_build_dir)
            
            # Determine WiX version and build accordingly
            wix_exe = os.path.join(wix_bin, "wix.exe") if os.name == 'nt' else os.path.join(wix_bin, "wix")
            candle_exe = os.path.join(wix_bin, "candle.exe")
            
            if os.path.exists(candle_exe):
                # WiX v3
                success = self._build_with_wix_v3(wix_processed, wixobj_file, msi_output)
            elif os.path.exists(wix_exe) or shutil.which("wix"):
                # WiX v4 (either in PATH or as dotnet tool)
                success = self._build_with_wix_v4(wix_processed, msi_output)
            else:
                print("❌ No WiX executable found!")
                return False
            
            # Cleanup
            if wix_processed.exists():
                wix_processed.unlink()
            if wixobj_file.exists():
                wixobj_file.unlink()
            
            if success:
                print(f"✅ MSI installer created successfully: {msi_output}")
                print(f"📦 File size: {msi_output.stat().st_size / 1024 / 1024:.1f} MB")
                return True
            else:
                return False
                
        except Exception as e:
            print(f"❌ Build failed: {e}")
            return False
    
    def _process_wix_template(self, template_path: Path, output_path: Path, 
                            guids: Dict[str, str], build_dir: str):
        """Process WiX template with dynamic values"""
        with open(template_path, 'r') as f:
            content = f.read()
        
        # Replace placeholders
        replacements = {
            "PUT-GUID-HERE": guids["upgrade_code"],
            "PUT-PRODUCT-GUID-HERE": guids["product_code"],
            "PUT-COMPONENT-MAIN-GUID": guids["component_main"],
            "PUT-COMPONENT-CONFIG-GUID": guids["component_config"],
            "PUT-COMPONENT-LICENSE-GUID": guids["component_license"],
            "PUT-COMPONENT-RESOURCES-GUID": guids["component_resources"],
            "1.0.0.0": self.config.get("version", "1.0.0.0"),
            "Morrigan": self.config.get("product_name", "Morrigan"),
            "Morrigan AI": self.config.get("manufacturer", "Morrigan AI"),
            "path\\to\\your\\morrigan.exe": os.path.join(build_dir, "morrigan.exe"),
        }
        
        for old, new in replacements.items():
            content = content.replace(old, new)
        
        with open(output_path, 'w') as f:
            f.write(content)
    
    def _build_with_wix_v3(self, wix_file: Path, wixobj_file: Path, msi_output: Path) -> bool:
        """Build with WiX Toolset v3"""
        print("🔧 Using WiX Toolset v3...")
        
        # Compile
        cmd_candle = ["candle.exe", str(wix_file), "-o", str(wixobj_file)]
        result = subprocess.run(cmd_candle, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Candle compilation failed: {result.stderr}")
            return False
        
        # Link
        cmd_light = ["light.exe", str(wixobj_file), "-o", str(msi_output)]
        result = subprocess.run(cmd_light, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Light linking failed: {result.stderr}")
            return False
        
        return True
    
    def _build_with_wix_v4(self, wix_file: Path, msi_output: Path) -> bool:
        """Build with WiX Toolset v4 (cross-platform)"""
        print("🔧 Using WiX Toolset v4...")
        
        # Try different command formats for WiX v4
        commands_to_try = [
            ["wix", "build", str(wix_file), "-o", str(msi_output)],
            ["dotnet", "wix", "build", str(wix_file), "-o", str(msi_output)],
            [os.path.join(self.wix_paths[0], "wix"), "build", str(wix_file), "-o", str(msi_output)]
        ]
        
        for cmd in commands_to_try:
            try:
                print(f"🔄 Trying command: {' '.join(cmd)}")
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
                
                if result.returncode == 0:
                    print("✅ WiX build successful!")
                    return True
                else:
                    print(f"⚠️ Command failed: {result.stderr}")
                    
            except FileNotFoundError:
                print(f"⚠️ Command not found: {cmd[0]}")
                continue
            except subprocess.TimeoutExpired:
                print(f"⏰ Command timeout: {cmd[0]}")
                continue
            except Exception as e:
                print(f"💥 Command exception: {e}")
                continue
        
        print("❌ All WiX v4 build attempts failed")
        return False

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Build Morrigan MSI Installer")
    parser.add_argument("--build-dir", help="Path to Morrigan build directory")
    parser.add_argument("--config", help="Path to installer config file")
    
    args = parser.parse_args()
    
    builder = WiXBuilder(args.config)
    success = builder.build_msi(args.build_dir)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()