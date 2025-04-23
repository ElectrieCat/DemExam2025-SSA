#!/bin/bash

# --- CONFIGURATION ---
EXPORT_DIR="/root/ad_import"
USERS_FILE="$EXPORT_DIR/Users_Details.csv"
LOG_FILE="$EXPORT_DIR/import_users.log"
TARGET_DOMAIN_DN="DC=au-team,DC=irpo"
# --- END CONFIGURATION ---

# --- Logging function ---
log_message() {
    local type="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$type] $message" | tee -a "$LOG_FILE"
}

log_message "INFO" "--- Starting User Import (v6 - awk FPAT Parsing, Correct Handling) ---"
log_message "INFO" "Target Domain DN: $TARGET_DOMAIN_DN"

if [ ! -f "$USERS_FILE" ]; then
    log_message "ERROR" "Users file not found: $USERS_FILE"; exit 1;
fi
line_count=$(wc -l < "$USERS_FILE")
if [ "$line_count" -le 1 ]; then
    log_message "INFO" "Users file '$USERS_FILE' contains no data rows."; exit 0;
fi

user_count=0
error_count=0

# ���������� Process Substitution � awk FPAT
while IFS='|' read -r samAccountName name description source_dn enabled homeDirectory homeDrive scriptPath password; do

    # �������� �������� ������
    if [ -z "$samAccountName" ]; then log_message "WARN" "Skipping line: empty SamAccountName."; continue; fi
    if [ -z "$password" ]; then log_message "WARN" "Skipping user '$samAccountName': empty password field."; continue; fi

    log_message "DEBUG" "Read values: SAM='$samAccountName', Name='$name', Desc='$description', SourceDN='$source_dn', Enabled='$enabled', HomeDir='$homeDirectory', HomeDrive='$homeDrive', Script='$scriptPath', Pass=(read)"

    # --- ������� ������ (��������, ��� ������ �������� ���������) ---
    log_message "DEBUG" "User '$samAccountName': Password variable length: ${#password}"
    log_message "DEBUG" "User '$samAccountName': Password variable hex dump:"
    echo -n "$password" | hexdump -C >> "$LOG_FILE" 2>&1
    # --- ����� ������� ������ ---

    # ���������� ������ ������� ������
    disable_flag=""; [[ "$enabled" == "False" ]] && disable_flag="--disabled"
    # ��������� ��� � �������
    givenName=$(echo "$name" | awk '{print $1}'); surname=$(echo "$name" | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')

    log_message "INFO" "Attempting to create user: '$samAccountName' ($name) with password from file."
    # ���������� ���������� $password, ����������� �� �����
    samba-tool user create "$samAccountName" "$password" \
        --use-username-as-cn \
        ${givenName:+--given-name="$givenName"} \
        ${surname:+--surname="$surname"} \
        ${description:+--description="$description"} \
        $disable_flag >> "$LOG_FILE" 2>&1
    create_rc=$?

    if [ $create_rc -ne 0 ]; then
        log_message "ERROR" "Failed to create user: '$samAccountName'. See log."
         error_msg=$(grep -A 1 "Attempting to create user: '$samAccountName'" "$LOG_FILE" | tail -n 1)
         log_message "ERROR" "samba-tool error might be: $error_msg"
        ((error_count++)); continue
    fi

    log_message "INFO" "User '$samAccountName' created successfully."
    ((user_count++)) # ����������� ������� ������� ���������

    # ��������� ��������� ������� ������ ���� ��� �� ������
    if [ -n "$homeDirectory" ]; then
        # !!! �����: ������������ Windows-���� $homeDirectory � Linux/Samba ����� !!!
        linuxHomeDir="$homeDirectory"
        log_message "INFO" "Setting HomeDirectory for $samAccountName: $linuxHomeDir"
        samba-tool user set homedirectory "$samAccountName" "$linuxHomeDir" >> "$LOG_FILE" 2>&1; if [ $? -ne 0 ]; then log_message "ERROR" "Failed setting HomeDirectory."; fi
    else
        log_message "DEBUG" "User '$samAccountName': HomeDirectory is empty, skipping."
    fi

    if [ -n "$homeDrive" ]; then
        log_message "INFO" "Setting HomeDrive for $samAccountName: $homeDrive"
        samba-tool user set homedrive "$samAccountName" "$homeDrive" >> "$LOG_FILE" 2>&1; if [ $? -ne 0 ]; then log_message "ERROR" "Failed setting HomeDrive."; fi
    else
         log_message "DEBUG" "User '$samAccountName': HomeDrive is empty, skipping."
    fi

     if [ -n "$scriptPath" ]; then
        log_message "INFO" "Setting ScriptPath for $samAccountName: $scriptPath"
        samba-tool user set scriptpath "$samAccountName" "$scriptPath" >> "$LOG_FILE" 2>&1; if [ $? -ne 0 ]; then log_message "ERROR" "Failed setting ScriptPath."; fi
     else
         log_message "DEBUG" "User '$samAccountName': ScriptPath is empty, skipping."
     fi

# ������ ����� awk ����� Process Substitution
done < <(awk -v FPAT='[^,]*|"[^"]*"' '
NR > 1 {
    out=""
    for (i=1; i<=NF; i++) {
        # ������� ���� �� ������� � �������� ������ ���
        gsub(/^[[:space:]]*"|["]*[[:space:]]*$/, "", $i)
        # ������� ������������ �������
        gsub(/[^[:print:]]/, "", $i)
        out = out (i>1 ? "|" : "") $i
    }
    print out
}' "$USERS_FILE")

log_message "INFO" "--- User Import Finished ---"
log_message "INFO" "Successfully created/processed users: $user_count"
log_message "INFO" "Errors during user creation: $error_count"
date | tee -a "$LOG_FILE"
exit $error_count