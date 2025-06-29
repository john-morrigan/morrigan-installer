# filepath: /morrigan-installer/morrigan-installer/templates/post_install.py
import os
import sys

def post_install():
    # Perform post-installation tasks here
    print("Post-installation tasks are starting...")

    # Example: Create a directory for logs
    log_dir = os.path.join(os.getenv('APPDATA'), 'Morrigan', 'logs')
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
        print(f"Created log directory at: {log_dir}")

    # Example: Write a welcome message to a log file
    with open(os.path.join(log_dir, 'install.log'), 'a') as log_file:
        log_file.write("Morrigan installation completed successfully.\n")

    print("Post-installation tasks completed.")

if __name__ == "__main__":
    post_install()