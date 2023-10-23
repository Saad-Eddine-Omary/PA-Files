#!/bin/bash
#==============================================================================
# Script Name    : functions.sh
# Description    : This script contains a collection of functions for use in other scripts.
# Args           : None
# Organization   : SecurifyStack
# Author         : OMARY Saad Eddine
# Email          : support@securifystack.com
# Created        : 16-10-2023
# Version        : 1.0
#==============================================================================
if [[ -f .env ]]; then
    source .env
else
    echo ".env file not found. Please make sure it exists in the script's directory."
    exit 1
fi

# Function to print dots while waiting for a task to complete
printDots(){
    for i in {1..3}; do
        echo -n "."
        sleep 1
    done
}

# Function to print a message in green
printGreen() {
    local text="$1"
    local tick="${GREEN}✔${RESET}"
    echo -e "\e[32m$text $tick\e[0m"
}

# Function to print a message in red
printRed() {
    local text="$1"
    local red_x="${RED}✘${RESET}"  # Use ✘ to represent the red "x"
    echo -e "\e[31m$text $red_x\e[0m"
}

# Function to log messages with timestamp
logMessage() {
    local message="$1"
    local status="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_file="${LOG_DIR}/${templateID}.log"

    # Create the log directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Log the message with timestamp and status
    echo "[$timestamp]: $message: $status" >> "$log_file"
}

# Function to log command execution with timestamp
logCommand() {
    local command="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_file="${LOG_DIR}/${templateID}_commands.log"

    # Create the log directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Log the command with timestamp
    echo "[$timestamp]: $command" >> "$log_file"
}

# Function to log and print messages with a specified status
logAndPrint() {
    local message="$1"
    local status="$2"
    logMessage "$message" "$status"
    if [ "$status" == "SUCCESS" ]; then
        printGreen "$message"
    else
        printRed "$message"
        exit 1
    fi
}

