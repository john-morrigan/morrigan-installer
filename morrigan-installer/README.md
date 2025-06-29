# Morrigan Installer Project

This project provides various methods to create an installer for the Morrigan application, including MSI, NSIS, and Inno Setup formats. Each method has its own configuration and build scripts to facilitate the installation process.

## Project Structure

- **installer/**: Contains the installer scripts and configurations for different installer formats.
  - **msi/**: Contains files related to the MSI installer.
    - `wix_installer.wxs`: WiX XML configuration for the MSI installer.
    - `build_msi.py`: Python script to build the MSI installer using the WiX toolset.
    - `product_config.py`: Configuration settings for the product.
  - **nsis/**: Contains files related to the NSIS installer.
    - `morrigan_installer.nsi`: NSIS script defining the installation process.
    - `build_nsis.py`: Python script to build the NSIS installer.
  - **innosetup/**: Contains files related to the Inno Setup installer.
    - `morrigan_setup.iss`: Inno Setup script for creating the installer.
    - `build_inno.py`: Python script to build the Inno Setup installer.

- **resources/**: Contains resources used by the installer.
  - **icons/**: Icon files for the installer and uninstaller.
  - **license/**: License information for the Morrigan application.
  - **images/**: Images used in the installer UI.

- **scripts/**: Contains utility scripts for preparing, signing, and validating the installer.
  - `prepare_installer.py`: Prepares the installer by gathering necessary files.
  - `sign_installer.py`: Signs the installer for authenticity.
  - `validate_installer.py`: Validates the generated installer.

- **templates/**: Contains template scripts for service installation and uninstallation.
  - `service_install.bat`: Template for installing the Morrigan service.
  - `service_uninstall.bat`: Template for uninstalling the Morrigan service.
  - `post_install.py`: Script executed after installation.

- **config/**: Contains configuration files for the installer.
  - `installer_config.json`: Configuration settings for the installer.
  - `signing_config.json`: Configuration settings for signing the installer.

## Building the Installer

To build the installer, navigate to the desired installer format directory (msi, nsis, or innosetup) and run the corresponding build script. For example, to build the MSI installer, execute:

```bash
python installer/msi/build_msi.py
```

Make sure to have the necessary tools installed for the chosen installer format.

## Usage

After building the installer, you can distribute it to users. The installer will guide them through the installation process for the Morrigan application.

## License

Refer to the LICENSE.rtf file in the resources/license directory for licensing information.