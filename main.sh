#!/bin/bash
#==============================================================================
#Script Name    : createLinuxTemplate.sh
#Description    : This script will create a Linux machine template using cloud-init
#Args           :
#Organization   : SecurifyStack
#Author         : OMARY Saad Eddine
#Email          : support@securifystack.com
#Created        : 16-10-2023
#Version        : 1.0
#Usage          : ./createLinuxTemplate.sh
#==============================================================================
# Source the functions file
if [[ -f functions.sh ]]; then
    source functions.sh
else
    echo "functions.sh file not found. Please make sure it exists in the script's directory."
    exit 1
fi

latestUbuntu="Mantic Minotaur"
latestDebian="Bookworm"

while true; do
    # Print a list of choices
    echo "Select an option:"
    echo "1. Select from a list of cloud images"
    echo "2. Enter manually a cloud image URL"
    echo "3. Quit"

    # Prompt the user to enter their choice
    read -p "Enter your choice (1/2/3): " choice

    # Use a case statement to handle the user's choice
    case $choice in
        1)
            while true; do
                # Print a list of choices
                echo -e "\nSelect a cloud image from the list:"
                echo "1. Latest Ubuntu LTS [$latestUbuntu]"
                echo "2. Latest Debian [$latestDebian]"
                echo "3. Quit"

                # Prompt the user to enter their choice
                read -p "Enter your choice (1/2/3): " choice

                # Use a case statement to handle the user's choice
                case $choice in
                    1)
                        echo -e "\nYou selected Latest Ubuntu LTS [$latestUbuntu]\n"
                        exit 0
                        ;;
                    2)
                        printGreen "\nYou selected Latest Debian [$latestDebian]\n"
                        


                        exit 0
                        ;;
                    3)
                        echo -e "\nGoodbye!\n"
                        # Add any cleanup code if needed
                        exit 0
                        ;;
                    *)
                        echo "Invalid choice. Please select 1, 2 or 3."
                        ;;
                esac
            done
            ;;
        2)
            read -p "Enter cloud image URL : " cloudDistrib
            echo "You selected $cloudDistrib"
            break
            ;;
        3)
            echo "Goodbye!"
            # Add any cleanup code if needed
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1, 2 or 3."
            ;;
    esac
done

exit 0