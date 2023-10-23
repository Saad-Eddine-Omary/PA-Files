#!/bin/bash
#==============================================================================
#Script Name    : createDebianTemplate.sh
#Description    : This script will create a Debian machine template using the latest Debian cloud image
#Args           :
#Organization   : SecurifyStack
#Author         : OMARY Saad Eddine
#Email          : support@securifystack.com
#Created        : 16-10-2023
#Version        : 1.0
#Usage          : ./createDebianTemplate.sh
#==============================================================================

# Prompt user to enter data related to the template
read -p "Enter template ID: " templateID
read -p "Enter RAM size (MB): " templateRAM
read -p "Enter number of cores: " templateCores
read -p "Enter the name of the template: " templateName
read -p "Enter the name of the bridge: " bridgeName
read -p "Enter a description for the template: " templateDescription
read -p "Enter storage ID: " storageID


# Source the functions file to load functions
if [[ -f functions.sh ]]; then
    source functions.sh
else
    echo "functions.sh file not found. Please make sure it exists in the script's directory."
    exit 1
fi

###### Main ######
log_file="${LOG_DIR}/${templateID}.log"
cd /tmp

# Download the latest Debian Cloud image
if wget $LATEST_DEBIAN_CLOUDIMG >> "$log_file" 2>&1; then
    logAndPrint "Downloaded the latest Debian Cloud image" "SUCCESS"
else
    logAndPrint "Failed to download the Debian Cloud image" "ERROR"
fi

# Create a virtual machine
if qm create "$templateID" --memory "$templateRAM" --core "$templateCores" --name "$templateName" --net0 "virtio,bridge=$bridgeName" --description "$templateDescription" >> "$log_file" 2>&1; then
    logAndPrint "Virtual machine created successfully" "SUCCESS"
else
    logAndPrint "Failed to create the virtual machine" "ERROR"
fi

# Import the disk
if qm importdisk "$templateID" "/tmp/$(basename "$LATEST_DEBIAN_CLOUDIMG")" "$storageID" >> "$log_file" 2>&1; then
    logAndPrint "Disk imported successfully" "SUCCESS"
else
    logAndPrint "Failed to import the disk" "ERROR"
fi

# Set SCSI properties
if qm set "$templateID" --scsihw "virtio-scsi-pci" --scsi0 "$storageID:vm-$templateID-disk-0" >> "$log_file" 2>&1; then
    logAndPrint "SCSI properties set successfully" "SUCCESS"
else
    logAndPrint "Failed to set SCSI properties" "ERROR"
fi

# Set boot options
if qm set "$templateID" --boot "c" --bootdisk "scsi0" >> "$log_file" 2>&1 && qm set "$templateID" --ide2 "$storageID:cloudinit" >> "$log_file" 2>&1; then
    logAndPrint "Boot options set successfully" "SUCCESS"
else
    logAndPrint "Failed to set boot options" "ERROR"
fi

# Set serial and VGA options
if qm set "$templateID" --serial0 "socket" --vga "serial0" >> "$log_file" 2>&1; then
    logAndPrint "Serial and VGA options set successfully" "SUCCESS"
else
    logAndPrint "Failed to set serial and VGA options" "ERROR"
fi

# Create a template
if qm template "$templateID" >> "$log_file" 2>&1; then
    logAndPrint "Template created successfully" "SUCCESS"
else
    logAndPrint "Failed to create the template" "ERROR"
fi

# Cleanup
rm -f /tmp/$(basename "$LATEST_DEBIAN_CLOUDIMG")

logMessage "Script completed" "INFO"
printGreen "Script completed"