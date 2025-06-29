import os
import subprocess

def build_nsis_installer():
    """Build the NSIS installer using the provided NSIS script."""
    nsis_script = os.path.join(os.path.dirname(__file__), 'morrigan_installer.nsi')
    
    # Check if the NSIS script exists
    if not os.path.exists(nsis_script):
        print(f"NSIS script not found: {nsis_script}")
        return False

    # Command to invoke the NSIS compiler
    command = ['makensis', nsis_script]
    
    try:
        # Run the NSIS compiler
        subprocess.run(command, check=True)
        print("NSIS installer built successfully.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error building NSIS installer: {e}")
        return False

if __name__ == "__main__":
    build_nsis_installer()