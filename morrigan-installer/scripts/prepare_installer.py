import os
import shutil
import json

def prepare_installer():
    # Load configuration
    with open('config/installer_config.json', 'r') as config_file:
        config = json.load(config_file)

    # Create necessary directories
    output_dir = config.get('output_directory', 'output')
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Copy resources to output directory
    resources = config.get('resources', [])
    for resource in resources:
        src = os.path.join('resources', resource)
        dst = os.path.join(output_dir, os.path.basename(resource))
        shutil.copy(src, dst)

    # Copy installer scripts
    installer_scripts = config.get('installer_scripts', [])
    for script in installer_scripts:
        src = os.path.join('installer', script)
        dst = os.path.join(output_dir, os.path.basename(script))
        shutil.copy(src, dst)

    print("Installer preparation complete. Files are ready in:", output_dir)

if __name__ == "__main__":
    prepare_installer()