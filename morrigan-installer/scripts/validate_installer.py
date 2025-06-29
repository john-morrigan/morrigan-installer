import os
import sys
import subprocess

def validate_installer(installer_path):
    """Validate the generated installer."""
    if not os.path.exists(installer_path):
        print(f"Installer not found at: {installer_path}")
        return False

    try:
        # Check if the installer can be executed
        result = subprocess.run([installer_path, '/?'], capture_output=True, text=True)
        if result.returncode != 0:
            print("Installer execution failed.")
            print(result.stderr)
            return False
        print("Installer validation successful.")
        return True
    except Exception as e:
        print(f"Error during validation: {e}")
        return False

def main():
    if len(sys.argv) != 2:
        print("Usage: python validate_installer.py <path_to_installer>")
        sys.exit(1)

    installer_path = sys.argv[1]
    if not validate_installer(installer_path):
        sys.exit(1)

if __name__ == "__main__":
    main()