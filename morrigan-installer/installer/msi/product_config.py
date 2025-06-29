# filepath: /morrigan-installer/morrigan-installer/installer/msi/product_config.py

class ProductConfig:
    """Configuration settings for the Morrigan MSI installer."""
    
    PRODUCT_NAME = "Morrigan"
    PRODUCT_VERSION = "0.1.0"
    PRODUCT_MANUFACTURER = "Morrigan AI"
    PRODUCT_DESCRIPTION = "LLM Monitoring Client for Morrigan"
    PRODUCT_UPGRADE_CODE = "PUT-GUID-HERE"  # Replace with a unique GUID for upgrades
    INSTALL_DIR = r"[ProgramFiles]\Morrigan"  # Default installation directory
    UNINSTALL_STRING = r"msiexec /x {product_code}"  # Command to uninstall the product
    INSTALLER_ICON = r"resources/icons/morrigan.ico"  # Path to the installer icon
    UNINSTALLER_ICON = r"resources/icons/uninstall.ico"  # Path to the uninstaller icon

    @staticmethod
    def get_product_code():
        """Generate a unique product code (GUID) for the installer."""
        import uuid
        return str(uuid.uuid4())  # Generate a new GUID for the product code

    @staticmethod
    def get_version():
        """Return the product version."""
        return ProductConfig.PRODUCT_VERSION

    @staticmethod
    def get_manufacturer():
        """Return the product manufacturer."""
        return ProductConfig.PRODUCT_MANUFACTURER

    @staticmethod
    def get_description():
        """Return the product description."""
        return ProductConfig.PRODUCT_DESCRIPTION