#!/bin/bash

# --- CONFIGURATION ---
EXPORT_DIR="/root/ad_import"
MEMBERSHIPS_FILE="$EXPORT_DIR/Groups_Memberships.csv"
LOG_FILE="$EXPORT_DIR/import_group_memberships.log"
# --- END CONFIGURATION ---

# --- Logging function ---
log_message() {
    local type="$1" # INFO, WARN, ERROR
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$type] $message" | tee -a "$LOG_FILE"
}

log_message "INFO" "--- Starting Group Membership Import (v2) ---"


if [ ! -f "$MEMBERSHIPS_FILE" ]; then
    log_message "ERROR" "Group memberships file not found: $MEMBERSHIPS_FILE"
    exit 1
fi

line_count=$(wc -l < "$MEMBERSHIPS_FILE")
if [ "$line_count" -le 1 ]; then
    log_message "INFO" "Group memberships file '$MEMBERSHIPS_FILE' contains no data rows. Nothing to import."
    exit 0
fi


membership_count=0
error_count=0

# Используем Process Substitution < <(...) чтобы цикл while выполнялся в текущей оболочке
# Используем awk с FPAT для парсинга CSV
# Поля: GroupDistinguishedName, MemberSamAccountName, MemberDistinguishedName
while IFS='|' read -r groupDistinguishedName memberSamAccountName memberDistinguishedName; do

    # Проверка базового чтения
    if [ -z "$groupDistinguishedName" ] || [ -z "$memberSamAccountName" ]; then
        log_message "WARN" "Skipping line with empty GroupDN or MemberSamAccountName: GroupDN='$groupDistinguishedName', MemberSAM='$memberSamAccountName'"
        continue
    fi

    # Извлекаем имя группы (SamAccountName) из GroupDistinguishedName (Предполагаем CN=GroupName,...)
    # Это может быть не надежно, если CN != SamAccountName. Но должно сработать для testgroup.
    groupName=$(echo "$groupDistinguishedName" | sed -n 's/^CN=\([^,]*\),.*/\1/p')

    if [ -z "$groupName" ]; then
         log_message "ERROR" "Could not extract group name from DN: '$groupDistinguishedName'. Skipping membership for '$memberSamAccountName'."
         ((error_count++))
         continue
    fi

    log_message "INFO" "Attempting to add user '$memberSamAccountName' to group '$groupName'"
    samba-tool group addmembers "$groupName" "$memberSamAccountName" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to add '$memberSamAccountName' to '$groupName'. See log."
         # Проверяем, существует ли пользователь/группа (частая причина ошибки)
        samba-tool user list | grep -q "^$memberSamAccountName$" || log_message "WARN" "Check: User '$memberSamAccountName' might not exist?"
        samba-tool group list | grep -q "^$groupName$" || log_message "WARN" "Check: Group '$groupName' might not exist?"
        ((error_count++)) # Счетчик теперь работает
    else
        log_message "INFO" "User '$memberSamAccountName' successfully added to group '$groupName'."
        ((membership_count++))
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
}' "$MEMBERSHIPS_FILE")


# --- Final Summary ---
log_message "INFO" "--- Group Membership Import Finished ---"
log_message "INFO" "Successfully added memberships: $membership_count"
log_message "INFO" "Errors during membership addition: $error_count"
date | tee -a "$LOG_FILE"

exit $error_count