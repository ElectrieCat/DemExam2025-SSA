#!/bin/bash

# --- CONFIGURATION ---
EXPORT_DIR="/root/ad_import"
SHARES_FILE="$EXPORT_DIR/SharedFolders_Permissions.csv"
OUTPUT_CONF_SNIPPET="$EXPORT_DIR/smb_shares_to_add.conf"
OUTPUT_MKDIR_COMMANDS="$EXPORT_DIR/directories_to_create.txt"
LOG_FILE="$EXPORT_DIR/configure_shares.log"
# --- END CONFIGURATION ---

# --- Logging function ---
log_message() {
    local type="$1" # INFO, WARN, ERROR
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$type] $message" | tee -a "$LOG_FILE"
}

log_message "INFO" "--- Starting Share Configuration Generation (v4 - Fixed While Loop Scope) ---"

if [ ! -f "$SHARES_FILE" ]; then
    log_message "ERROR" "Share permissions file not found: $SHARES_FILE"
    exit 1
fi

# Очищаем выходные файлы
> "$OUTPUT_CONF_SNIPPET"
> "$OUTPUT_MKDIR_COMMANDS"

# Собираем информацию по каждой шаре
declare -A shares_data # Массив будет изменяться в ТЕКУЩЕЙ оболочке

# --- ИЗМЕНЕНИЕ ЗДЕСЬ: Цикл while читает из Process Substitution ---
while IFS='|' read -r shareName sharePath scopeName trustee accessControlType accessRight; do

    # Очистка пробелов
    shareName=$(echo "$shareName" | sed 's/^[ \t]*//;s/[ \t]*$//')
    sharePath=$(echo "$sharePath" | sed 's/^[ \t]*//;s/[ \t]*$//')
    trustee=$(echo "$trustee" | sed 's/^[ \t]*//;s/[ \t]*$//')
    accessControlType=$(echo "$accessControlType" | sed 's/^[ \t]*//;s/[ \t]*$//')
    accessRight=$(echo "$accessRight" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Проверки на пустые значения
    if [ -z "$shareName" ]; then log_message "WARN" "Skipping line with empty ShareName."; continue; fi
    if [ -z "$accessRight" ]; then log_message "WARN" "Skipping permission for Trustee '$trustee' on share '$shareName' due to empty AccessRight."; continue; fi
    if [ -z "$trustee" ]; then log_message "WARN" "Skipping permission with AccessRight '$accessRight' on share '$shareName' due to empty Trustee."; continue; fi
    if [ -z "$accessControlType" ]; then log_message "WARN" "Skipping permission for Trustee '$trustee' on share '$shareName' due to empty AccessControlType."; continue; fi

    log_message "DEBUG" "Processing cleaned permission: Share='$shareName', Path='$sharePath', Trustee='$trustee', Type='$accessControlType', Right='$accessRight'"

    # Сохраняем путь (в текущей оболочке)
    if [[ -z "${shares_data[$shareName,path]}" ]]; then
        shares_data[$shareName,path]="$sharePath"
        log_message "DEBUG" "Stored path for share '$shareName': $sharePath"
    fi

    # Сохраняем разрешения (в текущей оболочке)
    case "$accessRight" in
        "Read")
            if [[ "$accessControlType" == "Allow" ]]; then shares_data[$shareName,read_allow]+="$trustee;";
            else shares_data[$shareName,read_deny]+="$trustee;"; fi
            log_message "DEBUG" "Added Read permission for '$trustee' on '$shareName'"
            ;;
        "Change"|"Full")
             if [[ "$accessControlType" == "Allow" ]]; then shares_data[$shareName,write_allow]+="$trustee;";
             else shares_data[$shareName,write_deny]+="$trustee;"; fi
            if [[ "$accessRight" == "Full" && "$accessControlType" == "Allow" ]]; then shares_data[$shareName,read_allow]+="$trustee;"; fi
            log_message "DEBUG" "Added $accessRight permission for '$trustee' on '$shareName'"
            ;;
        *)
            log_message "WARN" "Unknown access right '$accessRight' for '$trustee' on share '$shareName'. Skipping this permission entry."
            ;;
    esac
# --- ИЗМЕНЕНИЕ ЗДЕСЬ: Конец цикла while и начало Process Substitution ---
done < <(tr -d '\r' < "$SHARES_FILE" | awk -v FPAT='[^,]*|"[^"]*"' '
NR > 1 {
    out=""
    for (i=1; i<=NF; i++) {
        field = $i
        gsub(/^[[:space:]]*"|["]*[[:space:]]*$/, "", field)
        gsub(/[^[:print:]]/, "", field)
        out = out (i>1 ? "|" : "") field
    }
    print out
}')
# --- Конец Process Substitution ---

# --- Генерация конфигурации (остальная часть скрипта без изменений) ---
log_message "INFO" "Finished processing CSV. Generating output..."

echo "# --- Directory creation commands (Review and execute manually!) ---" > "$OUTPUT_MKDIR_COMMANDS"
echo "# --- smb.conf sections to add (Edit 'path = ...' entries!) ---" > "$OUTPUT_CONF_SNIPPET"
echo "" >> "$OUTPUT_CONF_SNIPPET"

unique_shares=$(echo "${!shares_data[@]}" | grep -oP '^[^,]+' | sort -u)

if [ -z "$unique_shares" ]; then
     log_message "WARN" "No share data was successfully stored in the array. Output files will be empty. Check processing logic."
     # Выведем содержимое массива для отладки
     declare -p shares_data >> "$LOG_FILE"
else
     log_message "INFO" "Found unique shares to process: $unique_shares"
fi

for share in $unique_shares; do
    win_path=${shares_data[$share,path]}
    # Проверка, что путь для шары был сохранен
    if [ -z "$win_path" ]; then
        log_message "WARN" "Path for share '$share' was not found in stored data. Skipping this share."
        continue
    fi

    linux_path="/srv/samba/shares/$share" # <--- ИЗМЕНИТЕ ЭТОТ ПУТЬ!
    log_message "INFO" "Generating configuration for share: '$share' (Original path: '$win_path')"

    echo "mkdir -p \"$linux_path\"" >> "$OUTPUT_MKDIR_COMMANDS"
    echo "chown root:root \"$linux_path\" # Or other owner/group" >> "$OUTPUT_MKDIR_COMMANDS"
    echo "chmod 770 \"$linux_path\"    # Or other base POSIX permissions" >> "$OUTPUT_MKDIR_COMMANDS"
    echo "# Configure ACLs for detailed permissions: setfacl ..." >> "$OUTPUT_MKDIR_COMMANDS"
    echo "" >> "$OUTPUT_MKDIR_COMMANDS"

    echo "" >> "$OUTPUT_CONF_SNIPPET"
    echo "[$share]" >> "$OUTPUT_CONF_SNIPPET"
    echo "    comment = Imported Share (Original: $win_path)" >> "$OUTPUT_CONF_SNIPPET"
    echo "    path = $linux_path  # <--- !!! REVIEW AND EDIT THIS PATH !!!" >> "$OUTPUT_CONF_SNIPPET"
    echo "    browseable = yes" >> "$OUTPUT_CONF_SNIPPET"
    echo "    read only = no" >> "$OUTPUT_CONF_SNIPPET"
    echo "    # Generated access lists:" >> "$OUTPUT_CONF_SNIPPET"

    format_list() {
        local list_str="$1"
        local formatted_list
        formatted_list=$(echo "$list_str" | tr ';' '\n' | sort -u | grep -v '^$' | paste -sd,)
        formatted_list=$(echo "$formatted_list" | sed \
            -e 's/\\/+/g' \
            -e 's/Everyone/Users/g' \
            -e 's/^\([^@+]\)/+\1/' \
            -e 's/,\([^@+]\)/, +\1/g' \
            -e 's/@\([^,+]*\)+\([^, "]*\)/@"\1+\2"/g' \
             )
        echo "$formatted_list"
    }

    read_allow_list=$(format_list "${shares_data[$share,read_allow]}")
    write_allow_list=$(format_list "${shares_data[$share,write_allow]}")
    read_deny_list=$(format_list "${shares_data[$share,read_deny]}")
    write_deny_list=$(format_list "${shares_data[$share,write_deny]}")
    valid_users_list=""

    if [ -n "$write_allow_list" ]; then valid_users_list="$write_allow_list"; fi
    if [ -n "$read_allow_list" ]; then
         if [ -n "$valid_users_list" ]; then valid_users_list="$valid_users_list,$read_allow_list"; else valid_users_list="$read_allow_list"; fi
         valid_users_list=$(echo "$valid_users_list" | tr ',' '\n' | sed 's/^[ \t+]*//;s/[ \t]*$//' | sort -u | grep -v '^$' | paste -sd,)
         valid_users_list=$(echo "$valid_users_list" | sed -e 's/^\([^@+]\)/+\1/' -e 's/,\([^@+]\)/, +\1/g' -e 's/@\([^,+]*\)+\([^, "]*\)/@"\1+\2"/g')
    fi

    if [ -n "$read_allow_list" ]; then echo "    read list = $read_allow_list" >> "$OUTPUT_CONF_SNIPPET"; fi
    if [ -n "$write_allow_list" ]; then echo "    write list = $write_allow_list" >> "$OUTPUT_CONF_SNIPPET"; fi
    if [ -n "$valid_users_list" ]; then echo "    valid users = $valid_users_list" >> "$OUTPUT_CONF_SNIPPET"; else echo "    # No explicit 'allow' permissions found." >> "$OUTPUT_CONF_SNIPPET"; fi
    if [ -n "$read_deny_list" ] || [ -n "$write_deny_list" ]; then
         deny_list=$(format_list "${shares_data[$share,read_deny]}${shares_data[$share,write_deny]}")
         echo "    # Denied users/groups: $deny_list" >> "$OUTPUT_CONF_SNIPPET"; echo "    invalid users = $deny_list" >> "$OUTPUT_CONF_SNIPPET";
    fi
    echo "    # Add other necessary Samba parameters (vfs objects, auditing, etc.)" >> "$OUTPUT_CONF_SNIPPET"
done


log_message "INFO" "--- Share Configuration Generation Finished ---"
log_message "INFO" "Directory creation commands saved to: $OUTPUT_MKDIR_COMMANDS"
log_message "INFO" "Configuration snippets for smb.conf saved to: $OUTPUT_CONF_SNIPPET"
log_message "WARN" "*** IMPORTANT: Edit the 'path = ...' entries in '$OUTPUT_CONF_SNIPPET' before use! ***"
log_message "WARN" "*** IMPORTANT: Execute commands from '$OUTPUT_MKDIR_COMMANDS' and configure filesystem permissions (ACL)! ***"
date | tee -a "$LOG_FILE"

exit 0