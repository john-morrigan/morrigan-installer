#!/usr/bin/env python3
"""
Morrigan Client Python Web Installer
Usage: python3 <(curl -sSL https://install.morrigan.ai/install.py)
"""
import os
import sys
import platform
import subprocess
import urllib.request
import tempfile
import tarfile
import zipfile
import json
from pathlib import Path


class WebInstaller:
    """Web-based installer for Morrigan Client"""
    
    def __init__(self):
        self.system = platform.system()
        self.machine = platform.machine().lower()
        self.repo = "MorriganAI/morrigan-client"
        self.version = "latest"
        self.force_user = False
        
        # Determine installation mode
        self.is_admin = os.geteuid() == 0 if hasattr(os, 'geteuid') else False
        
    def detect_platform(self):
        """Detect platform and architecture"""
        platform_map = {
            "Darwin": "macos",
            "Linux": "linux", 
            "Windows": "windows"
        }
        
        arch_map = {
            "x86_64": "x64",
            "amd64": "x64",
            "arm64": "arm64",
            "aarch64": "arm64"
        }
        
        self.platform = platform_map.get(self.system)
        self.arch = arch_map.get(self.machine, "x64")
        
        if not self.platform:
            raise Exception(f"Unsupported platform: {self.system}")
        
        self.package_name = f"morrigan-client-{self.platform}-{self.arch}"
        if self.system == "Windows":
            self.package_name += ".zip"
        else:
            self.package_name += ".tar.gz"
    
    def get_download_url(self):
        """Get download URL from GitHub releases"""
        if self.version == "latest":
            # Get latest release info
            api_url = f"https://api.github.com/repos/{self.repo}/releases/latest"
            try:
                with urllib.request.urlopen(api_url) as response:
                    release_data = json.loads(response.read())
                    
                # Find matching asset
                for asset in release_data.get("assets", []):
                    if asset["name"] == self.package_name:
                        return asset["browser_download_url"]
                        
                raise Exception(f"Package {self.package_name} not found in latest release")
                
            except Exception as e:
                print(f"Warning: Could not fetch release info: {e}")
                # Fallback to direct URL
                return f"https://github.com/{self.repo}/releases/latest/download/{self.package_name}"
        else:
            return f"https://github.com/{self.repo}/releases/download/v{self.version}/{self.package_name}"
    
    def download_and_extract(self):
        """Download and extract the package"""
        print("📦 Downloading Morrigan Client...")
        
        url = self.get_download_url()
        print(f"   From: {url}")
        
        # Create temp directory
        self.temp_dir = tempfile.mkdtemp()
        package_path = Path(self.temp_dir) / self.package_name
        
        # Download with progress
        def progress_hook(block_num, block_size, total_size):
            if total_size > 0:
                percent = min(100, (block_num * block_size * 100) // total_size)
                print(f"\r   Progress: {percent}%", end="", flush=True)
        
        try:
            urllib.request.urlretrieve(url, package_path, progress_hook)
            print("\n✓ Download completed")
        except Exception as e:
            raise Exception(f"Download failed: {e}")
        
        # Extract
        print("📁 Extracting package...")
        extract_dir = Path(self.temp_dir) / "extracted"
        extract_dir.mkdir()
        
        if package_path.suffix == ".zip":
            with zipfile.ZipFile(package_path, 'r') as zf:
                zf.extractall(extract_dir)
        else:
            with tarfile.open(package_path, 'r:gz') as tf:
                tf.extractall(extract_dir)
        
        # Find installer directory
        installer_dirs = list(extract_dir.glob("*installer*"))
        if installer_dirs:
            self.installer_dir = installer_dirs[0]
        else:
            # Fallback: use first directory
            subdirs = [d for d in extract_dir.iterdir() if d.is_dir()]
            if subdirs:
                self.installer_dir = subdirs[0]
            else:
                raise Exception("Could not find installer content")
        
        print("✓ Package extracted")
    
    def determine_install_paths(self):
        """Determine installation paths"""
        if self.force_user or not self.is_admin:
            # User installation
            self.install_mode = "user"
            home = Path.home()
            
            if self.system == "Windows":
                self.install_dir = home / "AppData" / "Local" / "Morrigan"
                self.bin_dir = self.install_dir
                self.config_dir = home / ".morrigan"
            else:
                self.install_dir = home / ".local" / "lib" / "morrigan"
                self.bin_dir = home / ".local" / "bin"
                self.config_dir = home / ".morrigan"
                
            print(f"🏠 User installation to: {self.install_dir}")
            
        else:
            # System installation
            self.install_mode = "system"
            
            if self.system == "Windows":
                self.install_dir = Path("C:/Program Files/Morrigan")
                self.bin_dir = self.install_dir
                self.config_dir = Path("C:/ProgramData/Morrigan")
            elif self.system == "Darwin":
                self.install_dir = Path("/usr/local/lib/morrigan")
                self.bin_dir = Path("/usr/local/bin")
                self.config_dir = Path("/etc/morrigan")
            else:  # Linux
                self.install_dir = Path("/usr/local/lib/morrigan")
                self.bin_dir = Path("/usr/local/bin")
                self.config_dir = Path("/etc/morrigan")
                
            print(f"🖥️  System installation to: {self.install_dir}")
    
    def install_files(self):
        """Install files to target directories"""
        print("📋 Installing files...")
        
        # Create directories
        self.install_dir.mkdir(parents=True, exist_ok=True)
        self.bin_dir.mkdir(parents=True, exist_ok=True)
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy binaries
        morrigan_dir = self.installer_dir / "morrigan"
        if morrigan_dir.exists():
            # Copy all files from morrigan directory
            import shutil
            for item in morrigan_dir.iterdir():
                dest = self.install_dir / item.name
                if item.is_file():
                    shutil.copy2(item, dest)
                    # Make executable
                    if not item.suffix or item.suffix in ['.exe', '']:
                        dest.chmod(0o755)
                else:
                    shutil.copytree(item, dest, dirs_exist_ok=True)
        
        # Create symlinks/shortcuts for CLI tools
        executables = ["morrigan", "morrigan-service", "morrigan-gui"]
        for exe in executables:
            exe_path = self.install_dir / exe
            if self.system == "Windows":
                exe_path = exe_path.with_suffix(".exe")
            
            if exe_path.exists():
                link_path = self.bin_dir / exe
                if self.system == "Windows":
                    link_path = link_path.with_suffix(".exe")
                    # On Windows, copy instead of symlink
                    import shutil
                    shutil.copy2(exe_path, link_path)
                else:
                    # Create symlink
                    if link_path.exists():
                        link_path.unlink()
                    link_path.symlink_to(exe_path)
        
        print("✓ Files installed")
    
    def create_config(self):
        """Create default configuration"""
        config_file = self.config_dir / ".env"
        
        if not config_file.exists():
            print("⚙️  Creating default configuration...")
            
            config_content = """# Morrigan Client Configuration
ENV=production
API_URL=https://morrigan-poc-serverless.azurewebsites.net/api
API_KEY=your_api_key_here

# Replace API_KEY with your actual key from https://dashboard.morrigan.ai
# For development, change ENV to 'development'
"""
            config_file.write_text(config_content)
            print(f"✓ Configuration created at: {config_file}")
            print("⚠️  Please edit the configuration file and set your API_KEY")
        else:
            print("✓ Configuration file already exists")
    
    def install_service(self):
        """Install as system service"""
        if self.install_mode != "system":
            print("⏭️  Skipping service installation (user mode)")
            return
        
        print("🔧 Installing system service...")
        
        try:
            # Use the installed service manager
            service_cmd = self.bin_dir / "morrigan-service"
            if self.system == "Windows":
                service_cmd = service_cmd.with_suffix(".exe")
            
            result = subprocess.run([str(service_cmd), "--install"], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✓ System service installed")
            else:
                print(f"⚠️  Service installation failed: {result.stderr}")
                
        except Exception as e:
            print(f"⚠️  Service installation error: {e}")
    
    def cleanup(self):
        """Clean up temporary files"""
        if hasattr(self, 'temp_dir'):
            import shutil
            shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def show_completion(self):
        """Show completion message and next steps"""
        print("\n🎉 Morrigan Client installation completed!")
        print("\n📋 Next steps:")
        
        print(f"1. Configure your API key:")
        print(f"   {self.config_dir / '.env'}")
        
        print(f"\n2. Test the installation:")
        print(f"   morrigan --config-check")
        print(f"   morrigan --test-api")
        
        print(f"\n3. Start monitoring:")
        if self.install_mode == "system":
            print(f"   morrigan-service --start")
        else:
            print(f"   morrigan-service --foreground")
        
        print(f"\n4. Or use the GUI:")
        print(f"   morrigan-gui")
        
        if self.install_mode == "user" and self.system != "Windows":
            print(f"\n⚠️  Make sure {self.bin_dir} is in your PATH:")
            shell_config = "~/.bashrc" if Path("~/.bashrc").expanduser().exists() else "~/.zshrc"
            print(f"   echo 'export PATH=\"{self.bin_dir}:$PATH\"' >> {shell_config}")
            print(f"   source {shell_config}")
        
        print(f"\n📚 Documentation: https://docs.morrigan.ai")
        print(f"🆘 Support: https://github.com/MorriganAI/morrigan-client/issues")
    
    def install(self):
        """Main installation process"""
        try:
            print("🚀 Morrigan Client Web Installer")
            print("=" * 35)
            
            self.detect_platform()
            print(f"🔍 Detected: {self.platform}-{self.arch}")
            
            self.determine_install_paths()
            self.download_and_extract()
            self.install_files()
            self.create_config()
            self.install_service()
            self.show_completion()
            
            return True
            
        except KeyboardInterrupt:
            print("\n❌ Installation cancelled by user")
            return False
        except Exception as e:
            print(f"\n❌ Installation failed: {e}")
            return False
        finally:
            self.cleanup()


def main():
    """Main entry point"""
    installer = WebInstaller()
    
    # Parse arguments
    if "--user" in sys.argv:
        installer.force_user = True
    
    if "--version" in sys.argv:
        try:
            version_idx = sys.argv.index("--version")
            installer.version = sys.argv[version_idx + 1]
        except (IndexError, ValueError):
            print("Error: --version requires a value")
            sys.exit(1)
    
    if "--help" in sys.argv:
        print("Morrigan Client Python Web Installer")
        print("\nUsage:")
        print("  python3 <(curl -sSL https://install.morrigan.ai/install.py)")
        print("  python3 <(curl -sSL https://install.morrigan.ai/install.py) --user")
        print("\nOptions:")
        print("  --user              Force user installation")
        print("  --version VERSION   Install specific version")
        print("  --help              Show this help")
        sys.exit(0)
    
    success = installer.install()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
