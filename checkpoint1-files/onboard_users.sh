#!/bin/bash

# ==============================================================================
# Requirement 8: Script Description
# This script automates user onboarding by reading a users.csv file, 
# managing user/group accounts, and setting directory permissions.
# ==============================================================================

# Check for root privileges (Requirement 1)
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root. Try using sudo."
   exit 1
fi

# Requirement 7: Logging Function
# Logs messages with timestamps to the audit log and the console.
LOG_FILE="/var/log/user_onboarding_audit.log"
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Requirement 1: Input File Definition
INPUT_FILE="users.csv"
if [[ ! -f "$INPUT_FILE" ]]; then
    log_event "ERROR: $INPUT_FILE not found in the current directory."
    exit 1
fi

# Start parsing the CSV file
while IFS=',' read -r username groupname shell; do
    # Remove carriage returns (common in files created on Windows)
    username=$(echo "$username" | tr -d '\r')
    groupname=$(echo "$groupname" | tr -d '\r')
    shell=$(echo "$shell" | tr -d '\r')

    # Skip empty lines and comment lines
    [[ -z "$username" ]] && continue
    [[ "$username" == "#"* ]] && continue

    # Requirement 7: Field Validation
    # Ensure all three columns have data.
    if [[ -z "$groupname" || -z "$shell" ]]; then
        log_event "ERROR: Missing fields for user '$username'. Skipping..."
        continue
    fi

    # Requirement 7: Username Format Validation
    # Matches lowercase letters, numbers, underscores, and hyphens.
    if ! [[ "$username" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        log_event "ERROR: Invalid username format '$username'. Skipping..."
        continue
    fi

    # Requirement 3: Group Management
    # Create the group if it does not already exist.
    if ! getent group "$groupname" >/dev/null; then
        groupadd "$groupname"
        log_event "INFO: Created group '$groupname'."
    fi

    # Requirement 2: User Account Management
    if id "$username" &>/dev/null; then
        # If user exists, update their login shell.
        usermod -s "$shell" "$username"
        log_event "INFO: Updated existing user '$username' shell to $shell."
    else
        # If user does not exist, create account with home directory.
        useradd -m -s "$shell" -g "$groupname" "$username"
        log_event "INFO: Created new user '$username' with shell $shell."
    fi

    # Requirement 3: Ensure user is a member of the group.
    usermod -aG "$groupname" "$username"

    # Requirement 4: Set Home Directory Permissions (700)
    # Owner has full access; no access for others.
    HOME_DIR="/home/$username"
    if [[ -d "$HOME_DIR" ]]; then
        chown "$username":"$groupname" "$HOME_DIR"
        chmod 700 "$HOME_DIR"
        log_event "INFO: Home directory permissions set for $username."
    fi

    # Requirement 5: Create Project Directory (750)
    # Owner: rwx, Group: r-x, Others: ---
    PROJ_DIR="/opt/projects/$username"
    mkdir -p "$PROJ_DIR"
    chown "$username":"$groupname" "$
