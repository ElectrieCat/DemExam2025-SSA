#!/bin/bash

# --- CONFIGURATION ---
EXPORT_DIR="/root/ad_import"
GROUPS_DETAILS_FILE="$EXPORT_DIR/Groups_Details.csv"
LOG_FILE="$EXPORT_DIR/import_groups_details.log"

# --- Определи DN целевого домена (нужен только для логов) ---
TARGET_DOMAIN_DN="DC=au-team,DC=irpo"   # <-- УБЕДИСЬ, ЧТО ЭТО ПРАВИЛЬНО!
# --- END CONFIGURATION ---

# --- Logging function ---
log_message() {
    local type="$1" # INFO, WARN, ERROR
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$type] $message" | tee -a "$LOG_FILE"
}

log_message "INFO" "--- Starting Group Details Import (v8 - Creating in default container) ---"
log_message "INFO" "Target Domain DN: $TARGET_DOMAIN_DN"


if [ ! -f "$GROUPS_DETAILS_FILE" ]; then
    log_message "ERROR" "Group details file not found: $GROUPS_DETAILS_FILE"
    exit 1
fi

line_count=$(wc -l < "$GROUPS_DETAILS_FILE")
if [ "$line_count" -le 1 ]; then
    log_message "INFO" "Group details file '$GROUPS_DETAILS_FILE' contains no data rows. Nothing to import."
    exit 0
fi

group_count=0
error_count=0

# Используем Process Substitution < <(...) чтобы цикл while выполнялся в текущей оболочке
# Используем awk с FPAT для парсинга CSV
while IFS='|' read -r samAccountName name description source_dn groupScope groupCategory; do
    # Очистка переменных
    type_param=""

    # Проверка базового чтения
    if [ -z "$samAccountName" ]; then
        log_message "WARN" "Skipping line possibly due to parsing issue or empty SamAccountName."
        continue
    fi

    log_message "DEBUG" "Read parsed values: SAM='$samAccountName', Name='$name', Desc='$description', SourceDN='$source_dn', Scope='$groupScope', Category='$groupCategory'"
    log_message "INFO" "Group '$samAccountName' will be created in the default container (likely CN=Users)."

    # --- НЕ ИСПОЛЬЗУЕМ ТРАНСФОРМАЦИЮ DN ДЛЯ ПУТИ ---
    # --- НЕ ИЗВЛЕКАЕМ OU PATH ---

    # Map GroupCategory (GroupScope не используется при создании по умолчанию)
    case "$groupCategory" in
        "Distribution") type_param="Distribution" ;;
        "Security") type_param="Security" ;; # Явно указываем Security
        *) log_message "WARN" "Unknown or empty GroupCategory ('$groupCategory') for group '$samAccountName'. Using default (Security)." ; type_param="Security" ;;
    esac

    log_message "INFO" "Attempting to create group: '$samAccountName'"
    # Вызываем БЕЗ --groupou
    samba-tool group add "$samAccountName" \
        ${description:+--description="$description"} \
        ${type_param:+--group-type="$type_param"} >> "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create group: '$samAccountName'. See log."
        ((error_count++)) # Счетчик теперь работает
    else
        log_message "INFO" "Group '$samAccountName' created successfully (in default container)."
        # Можно добавить ldbsearch для записи реального DN в лог
        real_dn=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectClass=group)(sAMAccountName=$samAccountName))" distinguishedName | grep "^distinguishedName:" | sed 's/^distinguishedName: //')
        log_message "INFO" "Actual DN for '$samAccountName': $real_dn"
        ((group_count++))
    fi

# Читаем вывод awk через Process Substitution
done < <(awk -v FPAT='[^,]*|"[^"]*"' '
NR > 1 {
    out=""
    for (i=1; i<=NF; i++) {
        gsub(/^"|"$/, "", $i)
        out = out (i>1 ? "|" : "") $i
    }
    print out
}' "$GROUPS_DETAILS_FILE")


# --- Final Summary ---
log_message "INFO" "--- Group Details Import Finished ---"
log_message "INFO" "Successfully created groups: $group_count"
log_message "INFO" "Errors during group creation: $error_count"
date | tee -a "$LOG_FILE"

exit $error_count