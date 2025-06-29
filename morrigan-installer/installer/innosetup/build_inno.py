import subprocess
import os

def build_inno_installer():
    # Path to the Inno Setup compiler
    inno_setup_path = r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe"  # Update this path if necessary
    script_path = os.path.join(os.path.dirname(__file__), 'morrigan_setup.iss')

    # Command to run the Inno Setup compiler
    command = [inno_setup_path, script_path]

    try:
        # Run the Inno Setup compiler
        subprocess.run(command, check=True)
        print("Inno Setup installer built successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error building Inno Setup installer: {e}")

if __name__ == "__main__":
    build_inno_installer()