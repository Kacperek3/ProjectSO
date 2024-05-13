#!/bin/bash

# Function to display an error message dialog
show_error() {
    zenity --error --text "$1" --title "Error"
}

# Function to display a confirmation dialog
confirm_backup() {
    zenity --question --text "Do you want to backup '$source_folder' to '$destination_folder'?" --title "Backup Confirmation"
}

# Function to perform the backup
perform_backup() {
    # Check if the destination folder exists, if not, create it
    mkdir -p "$destination_folder"

    # Copy the contents of the source folder to the destination folder
    cp -r "$source_folder"/* "$destination_folder"

    if [ $? -eq 0 ]; then
        zenity --info --text "Backup completed successfully." --title "Backup Complete"
    else
        show_error "Backup failed."
    fi
}

# Prompt the user to select the source folder to backup
source_folder=$(zenity --file-selection --directory --title="Select Source Folder")

if [ -z "$source_folder" ]; then
    show_error "No source folder selected. Exiting."
    exit 1
fi

# Prompt the user to select the destination folder for the backup
destination_folder=$(zenity --file-selection --directory --title="Select Destination Folder")

if [ -z "$destination_folder" ]; then
    show_error "No destination folder selected. Exiting."
    exit 1
fi

# Confirm the backup operation with the user
if confirm_backup; then
    perform_backup
else
    zenity --info --text "Backup operation cancelled." --title "Backup Cancelled"
fi
