#!/bin/bash

# Function to display an error message dialog
show_error() {
    zenity --error --text "$1" --title "Error"
}

# Function to display a confirmation dialog
confirm_backup() {
    zenity --question --text "Do you want to backup '$source_folder' to '$destination_folder'?" --title "Backup Confirmation"
}

# Function to ask if the user wants to create a zip file or normal backup
confirm_backup_options() {
    backup_choices=$(zenity --list --checklist --title="Backup Options" --text="Select backup options:" --column="Select" --column="Option" TRUE "Normal Backup" FALSE "Create Zip" FALSE "Password Protect")
    create_zip=false
    create_normal_backup=false
    password_protect=false

    if [[ $backup_choices == *"Normal Backup"* ]]; then
        create_normal_backup=true
    fi
    if [[ $backup_choices == *"Create Zip"* ]]; then
        create_zip=true
    fi
    if [[ $backup_choices == *"Password Protect"* ]]; then
        password_protect=true
    fi

    if ! $create_normal_backup && ! $create_zip; then
        show_error "No backup option selected. Exiting."
        exit 1
    fi

    if $password_protect && ! $create_zip; then
        show_error "Password protection can only be applied to zip files. Exiting."
        exit 1
    fi
}

perform_backup() {
    # Check if the destination folder exists, if not, create it
    mkdir -p "$destination_folder"

    # Check if a backup already exists in the destination folder
    if [ -e "$destination_folder/backup" ]; then
        # If a backup exists, prompt the user to confirm overwrite or create a new version
        zenity --question --text "A backup already exists in the destination folder. Do you want to overwrite it?" --title "Backup Exists"
        if [ $? -eq 0 ]; then
            # If the user confirms overwrite, remove the existing backup
            rm -rf "$destination_folder/backup"
        else
            # If the user chooses not to overwrite, create a new version of the backup
            timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
            destination_folder="$destination_folder/backup_$timestamp"
            mkdir "$destination_folder"
        fi
    fi

    # Change to the source directory
    cd "$source_folder"

    # Perform normal backup
    if $create_normal_backup; then
        cp -r . "$destination_folder"
        if [ $? -eq 0 ]; then
            zenity --info --text "Normal backup completed successfully." --title "Backup Complete"
        else
            show_error "Normal backup failed."
        fi
    fi

    # Create zip backup
    if $create_zip; then
        if $password_protect; then
            password=$(zenity --password --title="Enter Password for Zip File")
            if [ -z "$password" ]; then
                show_error "No password entered. Exiting."
                exit 1
            fi
            zip -r -e --password "$password" "$destination_folder/backup.zip" .
        else
            zip -r "$destination_folder/backup.zip" .
        fi

        if [ $? -eq 0 ]; then
            zenity --info --text "Backup zip created successfully." --title "Zip Backup Complete"
        else
            show_error "Failed to create zip file."
        fi

        # Set permissions on the backup
        set_permissions
    fi
}

# Function to set permissions on the backup
set_permissions() {
    permissions=$(zenity --entry --title="Set Permissions" --text="Enter permissions (e.g., 755):")
    if [ -z "$permissions" ]; then
        show_error "No permissions entered. Exiting."
        exit 1
    fi

    if [[ $create_normal_backup == true ]]; then
        chmod -R "$permissions" "$destination_folder"
    fi
    if [[ $create_zip == true ]]; then
        unzip -l "$destination_folder/backup.zip" | awk 'NR>3 {print $4}' | xargs chmod "$permissions"
    fi

    if [ $? -eq 0 ]; then
        zenity --info --text "Permissions set successfully." --title "Permissions Set"
    else
        show_error "Failed to set permissions."
    fi
}

# Function to select source folder
select_source_folder() {
    source_folder=$(zenity --file-selection --directory --title="Select Source Folder" | sed 's/^"//' | sed 's/"$//')
    if [ -z "$source_folder" ]; then
        show_error "No source folder selected. Exiting."
        display_menu
    fi
    display_menu "$source_folder" "$destination_folder"
}

# Function to select destination folder
select_destination_folder() {
    destination_folder=$(zenity --file-selection --directory --title="Select Destination Folder" | sed 's/^"//' | sed 's/"$//')
    if [ -z "$destination_folder" ]; then
        show_error "No destination folder selected. Exiting."
        display_menu
    fi
    display_menu "$source_folder" "$destination_folder"
}

# Function to display the menu
display_menu() {
    source_folder="$1"
    destination_folder="$2"

    # Prepend selected source and destination folders to the options list
    options=("Run Backup" "Select Source Folder: $source_folder" "Select Destination Folder: $destination_folder")

    choice=$(zenity --list --title="Backup Menu" --column="Options" "${options[@]}" --ok-label="Run Backup" --cancel-label="Exit")


    case $choice in
        "Run Backup")
            if [ -z "$source_folder" ] || [ -z "$destination_folder" ]; then
                    show_error "Source and destination folders are required. Please select them first."
                    display_menu "$source_folder" "$destination_folder"
                fi
                if confirm_backup; then
                    confirm_backup_options
                    perform_backup
                else
                    zenity --info --text "Backup operation cancelled." --title "Backup Cancelled"
                fi
                display_menu "$source_folder" "$destination_folder" ;;
        "Select Source Folder: $source_folder")
            select_source_folder ;;
        "Select Destination Folder: $destination_folder")
            select_destination_folder ;;
    esac

    ret=$?

    if ((ret==0)); then
        exit 1
    fi
}

# Display the initial menu
display_menu
