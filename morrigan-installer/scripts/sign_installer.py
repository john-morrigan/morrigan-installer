import os
import subprocess
import json

def load_signing_config():
    with open('config/signing_config.json') as f:
        return json.load(f)

def sign_installer(installer_path, certificate_path, password):
    command = [
        'signtool', 'sign', 
        '/f', certificate_path, 
        '/p', password, 
        '/t', 'http://timestamp.digicert.com', 
        installer_path
    ]
    
    try:
        subprocess.run(command, check=True)
        print(f"Successfully signed: {installer_path}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to sign {installer_path}: {e}")

def main():
    signing_config = load_signing_config()
    installer_path = signing_config['installer_path']
    certificate_path = signing_config['certificate_path']
    password = signing_config['password']

    sign_installer(installer_path, certificate_path, password)

if __name__ == "__main__":
    main()