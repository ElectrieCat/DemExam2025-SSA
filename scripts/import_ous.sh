#!/bin/bash

# --- CONFIGURATION ---
EXPORT_DIR="/root/ad_import" # Specify the path to the folder with CSV files
OU_STRUCTURE_FILE="$EXPORT_DIR/OUs_Structure.csv"
LOG_FILE="$EXPORT_DIR/import_ous.log"
# --- END CONFIGURATION ---

# --- Logging function ---
log_message() {
    local type="$1" # INFO, WARN, ERROR
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$type] $message" | tee -a "$LOG_FILE"
}

log_message "INFO" "--- Starting OU Structure Import (v5.2 - No DC OU assumption, Show check) ---"

# --- Check if essential tools exist ---
command -v samba-tool >/dev/null 2>&1 || { log_message "ERROR" "samba-tool command not found."; exit 1; }
command -v awk >/dev/null 2>&1 || { log_message "ERROR" "awk command not found."; exit 1; }
command -v grep >/dev/null 2>&1 || { log_message "ERROR" "grep command not found."; exit 1; }
command -v sed >/dev/null 2>&1 || { log_message "ERROR" "sed command not found."; exit 1; }


# --- Get Target Domain DN ---
target_domain_dn=""
log_message "INFO" "Attempting to determine Target Domain DN..."
target_host="127.0.0.1"
domain_info_output=$(samba-tool domain info "$target_host" 2>/dev/null)
info_rc=$?
if [ $info_rc -eq 0 ]; then
    domain_name_line=$(echo "$domain_info_output" | grep -E "^Domain[[:space:]]+:")
    if [ -n "$domain_name_line" ]; then
         domain_name=$(echo "$domain_name_line" | cut -d ':' -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//')
         if [ -n "$domain_name" ]; then
             target_domain_dn=$(echo "$domain_name" | tr '[:upper:]' '[:lower:]' | sed 's/\./,DC=/g; s/^/DC=/')
         fi
    fi
fi
if [ -z "$target_domain_dn" ]; then # Fallback to realm
    realm=$(samba-tool testparm --parameter-name="realm" -s 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$realm" ]; then
        target_domain_dn=$(echo "$realm" | tr '[:upper:]' '[:lower:]' | sed 's/\./,DC=/g; s/^/DC=/')
    fi
fi
if [ -z "$target_domain_dn" ]; then
    log_message "ERROR" "Could not determine Target Domain DN. Exiting."
    exit 1
fi
log_message "INFO" "Using Target Domain DN: $target_domain_dn"


# --- !!! Define Source Domain Suffix from your CSVs !!! ---
SOURCE_DOMAIN_DN_SUFFIX="DC=office,DC=local" # <-- ENSURE THIS IS CORRECT
log_message "INFO" "Expecting Source Domain Suffix in CSV: $SOURCE_DOMAIN_DN_SUFFIX"

# --- Define the standard Domain Controllers OU DN (for comparison/logging only now) ---
STD_DC_OU_DN="OU=Domain Controllers,${target_domain_dn}"


# --- Check if OU file exists ---
if [ ! -f "$OU_STRUCTURE_FILE" ]; then
    log_message "ERROR" "OU structure file not found: $OU_STRUCTURE_FILE"
    exit 1
fi


# --- Counters ---
ou_count=0
error_count=0

# --- Function to check if OU *really* exists using 'ou show' ---
ou_exists() {
    local dn_to_check="$1"
    log_message "DEBUG" "Checking existence of OU '$dn_to_check' using 'samba-tool ou show'..."
    samba-tool ou show "$dn_to_check" > /dev/null 2>&1
    local rc=$?
    if [ $rc -eq 0 ]; then
        log_message "DEBUG" "OU '$dn_to_check' exists."
        return 0
    else
        log_message "DEBUG" "OU '$dn_to_check' does not exist (or error checking)."
        return 1
    fi
}

# --- Function to ensure parent OU exists (recursive) ---
ensure_parent_ou_exists() {
    local child_dn="$1"
    local parent_dn
    parent_dn=$(echo "$child_dn" | sed 's/^[^,]*,//')

    # Base case 1: Parent is the target domain root
    if [ "$parent_dn" == "$target_domain_dn" ]; then
        return 0
    fi

    # Base case 2: Parent DN is invalid or outside target domain
    if [ -z "$parent_dn" ] || [[ ! "$parent_dn" == *",${target_domain_dn}" ]]; then
        log_message "ERROR" "Invalid parent DN detected ('$parent_dn') for '$child_dn'. Does not match target domain '$target_domain_dn'. Stopping recursion."
        return 1
    fi

    # Check if parent *actually* exists using the robust check
    if ou_exists "$parent_dn"; then
        return 0
    else
        # Parent does not exist, ensure *its* parent exists first (recursive call)
        log_message "INFO" "Parent OU '$parent_dn' for '$child_dn' not found. Ensuring its parent exists first..."
        if ensure_parent_ou_exists "$parent_dn"; then
             # Parent's parent is ensured. Now create the immediate parent.
             # We still skip *attempting* to create STD_DC_OU_DN, just in case,
             # but we rely on ou_exists having failed earlier if it wasn't really there.
             if [[ "$parent_dn" == "$STD_DC_OU_DN" ]]; then
                 log_message "ERROR" "Attempting to create parent '$parent_dn', but it is the standard DC OU and was reported as non-existent by 'ou show'. This indicates a problem with the Samba DC setup. Cannot proceed for child '$child_dn'."
                 return 1 # Cannot proceed if standard OU is missing
             fi

             # Create other missing parents
             log_message "INFO" "Attempting to create missing parent OU: $parent_dn"
             samba-tool ou create "$parent_dn" >> "$LOG_FILE" 2>&1
             local create_rc=$?
             # Capture specific error message from log if creation failed
             local error_msg=""
             if [ $create_rc -ne 0 ]; then
                error_msg=$(grep -A 1 "Attempting to create missing parent OU: $parent_dn" "$LOG_FILE" | tail -n 1)
             fi

             if [ $create_rc -eq 0 ]; then
                 log_message "INFO" "Parent OU '$parent_dn' created successfully."
                 return 0
             else
                 log_message "ERROR" "Failed to create parent OU '$parent_dn' for '$child_dn'. Error: $error_msg"
                 return 1
             fi
        else
            # Failed to ensure the parent's parent
            log_message "ERROR" "Could not ensure parent hierarchy for '$parent_dn'."
            return 1
        fi
    fi
}


# --- Read file using Process Substitution ---
while IFS= read -r source_dn; do
    if [ -z "$source_dn" ]; then
        log_message "WARN" "Skipping empty DN line in OU file."
        continue
    fi

    # --- DN Transformation ---
    target_dn=""
    if [[ "$source_dn" == *",${SOURCE_DOMAIN_DN_SUFFIX}" ]]; then
        ou_part=$(echo "$source_dn" | sed "s/,${SOURCE_DOMAIN_DN_SUFFIX}//")
        target_dn="${ou_part},${target_domain_dn}"
        log_message "INFO" "Transforming Source DN '$source_dn' -> Target DN '$target_dn'"
    elif [[ "$source_dn" == "$SOURCE_DOMAIN_DN_SUFFIX" ]]; then
         log_message "WARN" "Source DN matches source suffix exactly ('$source_dn'). Skipping."
         continue
    else
        log_message "WARN" "Source DN '$source_dn' does not end with expected suffix '$SOURCE_DOMAIN_DN_SUFFIX'. Using as is."
        target_dn="$source_dn"
        if [[ ! "$target_dn" == *",${target_domain_dn}" ]] && [ "$target_dn" != "$target_domain_dn" ]; then
             log_message "ERROR" "DN '$target_dn' does not belong to target domain '$target_domain_dn'. Skipping."
             ((error_count++))
             continue
        fi
    fi
    # --- End DN Transformation ---

    # --- Skip explicit creation of standard DC OU itself ---
     if [[ "$target_dn" == "$STD_DC_OU_DN" ]]; then
         log_message "INFO" "Skipping explicit creation of standard OU: $target_dn (Should exist or be handled as parent)."
         continue
     fi

    # Check if the target OU already exists using the reliable check
    if ou_exists "$target_dn"; then
        log_message "INFO" "Target OU '$target_dn' already exists. Skipping creation."
        continue
    fi

    # Ensure the parent OU exists before attempting to create the child
    if ensure_parent_ou_exists "$target_dn"; then
        # Parent exists or was created successfully, now try creating the child OU
        log_message "INFO" "Attempting to create Target OU: $target_dn"
        samba-tool ou create "$target_dn" >> "$LOG_FILE" 2>&1
        create_rc=$?
        # Capture specific error message from log if creation failed
        error_msg=""
        if [ $create_rc -ne 0 ]; then
            error_msg=$(grep -A 1 "Attempting to create Target OU: $target_dn" "$LOG_FILE" | tail -n 1)
         fi

        if [ $create_rc -eq 0 ]; then
            log_message "INFO" "Target OU '$target_dn' created successfully."
            ((ou_count++))
        else
            log_message "ERROR" "Failed to create Target OU: $target_dn. Error: $error_msg"
            ((error_count++))
        fi
    else
        # Parent OU could not be ensured
        log_message "SKIP" "Skipping creation of Target OU '$target_dn' because its parent hierarchy could not be ensured."
        ((error_count++))
    fi

done < <(tail -n +2 "$OU_STRUCTURE_FILE" | awk -F'"' '{print $2}') # Use Process Substitution


# --- Final Summary ---
log_message "INFO" "--- OU Structure Import Finished ---"
log_message "INFO" "Successfully created OUs in this run: $ou_count"
log_message "INFO" "Errors encountered (incl. skipped/failed OUs): $error_count"
date | tee -a "$LOG_FILE"

exit $error_count