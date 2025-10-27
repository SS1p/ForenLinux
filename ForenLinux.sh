
#!/bin/bash

# Linux Forensics Script - ForenLinux.sh
# Author: SS1P 
# Version: 1.3
# Purpose: Collect Linux system data for incident response, forensic analysis, and routine auditing

# Default Configuration
BASE_DIR="/mnt/forenlinux_$(date +%Y%m%d%H%M%S)"
OUTPUT_DIR="${BASE_DIR}/output"
HASH_ALGO="md5,sha256"
LOG_DIR="${OUTPUT_DIR}/log"
CONF_FILE="/etc/forenlinux.conf"
REPORT_FILE="${OUTPUT_DIR}/forenlinux_report_$(date +%Y%m%d%H%M%S).txt"
SILENT_MODE=0
QUICK_MODE=0
DEEP_MODE=0
COLLECT_SCOPE="all"
ENCRYPT_PASS=""
LOW_PERF_MODE=0
USE_PROGRESS_BAR=1  # Enable progress bar by default

# Log Function
log_message() {
  local level="$1"
  local msg="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
  local user=$(whoami)
  local cmd="${BASH_COMMAND:-unknown}"
  local target="${TARGET:-unknown}"
  local result="${RESULT:-unknown}"
  local detail="${DETAIL:-unknown}"
  local log_entry="[$timestamp] [$level] [user:$user] [command:$cmd] [target:$target] [result:$result] [detail:$detail]"
  mkdir -p "${LOG_DIR}"
  local log_file="${LOG_DIR}/forenlinux_log_$(date +%Y%m%d_%H).log"
  echo "$log_entry" >> "$log_file" 2>/dev/null
  chmod 600 "$log_file" 2>/dev/null
  if [ $SILENT_MODE -eq 0 ] && [ "$level" != "INFO" ]; then
    echo "$log_entry"
  fi
}

# Progress Bar Function using dialog
show_progress_dialog() {
  local percentage=$1
  local message=$2
  if [ $SILENT_MODE -eq 0 ] && [ $USE_PROGRESS_BAR -eq 1 ] && command -v dialog &> /dev/null; then
    dialog --gauge "$message" 10 70 "$percentage" 2> /dev/null
  elif [ $SILENT_MODE -eq 0 ] && [ $USE_PROGRESS_BAR -eq 1 ]; then
    # Fallback to text-based progress bar if dialog is not available
    local bars=$((percentage / 10))
    local spaces=$((10 - bars))
    printf "\r[%*s%*s] %d%% %s" $bars "#" $spaces " " "$percentage" "$message"
  fi
}


# Initialize Progress Bar
init_progress() {
  if [ $SILENT_MODE -eq 0 ] && [ $USE_PROGRESS_BAR -eq 1 ] && command -v dialog &> /dev/null; then
    dialog --title "ForenLinux Progress" --gauge "Initializing..." 10 70 0 2> /dev/null
  elif [ $SILENT_MODE -eq 0 ] && [ $USE_PROGRESS_BAR -eq 1 ]; then
    printf "[----------] 0%% Initializing...\n"
  fi
}

# Detect OS Distribution
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_VERSION="$VERSION_ID"
  else
    OS_ID="unknown"
    OS_VERSION="unknown"
  fi
  log_message "INFO" "OS detected" "result:success" "detail:ID=$OS_ID,VERSION=$OS_VERSION"
}

# Check Privileges
check_privilege() {
  if [ "$EUID" -ne 0 ]; then
    log_message "ERROR" "Root privilege required" "result:failed" "detail:Current UID=$EUID"
    if [ $SILENT_MODE -eq 0 ]; then
      echo "Please run the script with sudo: sudo $0 $@"
    fi
    exit 1
  fi
}

# Setup Base Directory and Permissions
setup_base_dir() {
  if ! mkdir -p "$BASE_DIR"; then
    log_message "ERROR" "Failed to create base directory" "result:failed" "detail:Path=$BASE_DIR"
    if [ $SILENT_MODE -eq 0 ]; then
      echo "Failed to create base directory $BASE_DIR, please check permissions or change the path"
    fi
    exit 2
  fi
  chmod 700 "$BASE_DIR" 2>/dev/null
  OUTPUT_DIR="${BASE_DIR}/output"
  LOG_DIR="${OUTPUT_DIR}/log"
  mkdir -p "$OUTPUT_DIR" "$LOG_DIR"
  chmod -R 700 "$OUTPUT_DIR" 2>/dev/null
  log_message "INFO" "Base directory setup completed" "result:success" "detail:Path=$BASE_DIR"
}

# Check Output Directory
check_output_dir() {
  if ! test -w "$OUTPUT_DIR"; then
    log_message "ERROR" "Output directory not writable" "result:failed" "detail:Path=$OUTPUT_DIR"
    if [ $SILENT_MODE -eq 0 ]; then
      echo "Output directory $OUTPUT_DIR is not writable, please change the path"
    fi
    exit 2
  fi
}

# Check Dependency Tools
check_dependencies() {
  local deps="dd md5sum sha256sum lsof ps netstat ss find stat awk grep tar"
  local missing=""
  for dep in $deps; do
    if ! which "$dep" &>/dev/null; then
      missing="$missing $dep"
    fi
  done
  if [ -n "$missing" ]; then
    log_message "WARN" "Missing dependencies" "result:partial" "detail:Missing=$missing"
  fi
  # Check if dialog is available for progress bar
  if ! command -v dialog &> /dev/null; then
    log_message "WARN" "dialog tool not found, using text-based progress bar" "result:partial" "detail:dialog missing"
  fi
}

# Collect System Basic Information
collect_system_info() {
  local sys_dir="${OUTPUT_DIR}/system"
  mkdir -p "$sys_dir" && chmod 700 "$sys_dir"
  local cmds=(
    "cat /etc/os-release > $sys_dir/os_release.txt"
    "uname -r > $sys_dir/kernel_version.txt"
    "hostname > $sys_dir/hostname.txt"
    "date > $sys_dir/system_time.txt"
    "timedatectl > $sys_dir/timezone.txt 2>/dev/null || date > $sys_dir/timezone.txt"
    "ntpq -p > $sys_dir/ntp_status.txt 2>/dev/null || chronyc sources > $sys_dir/ntp_status.txt 2>/dev/null"
    "lscpu > $sys_dir/cpu_info.txt 2>/dev/null || cat /proc/cpuinfo > $sys_dir/cpu_info.txt"
    "free -h > $sys_dir/memory_info.txt"
    "lsblk > $sys_dir/disk_partitions.txt 2>/dev/null && fdisk -l >> $sys_dir/disk_partitions.txt 2>/dev/null"
    "mount > $sys_dir/mount_points.txt"
  )
  for cmd in "${cmds[@]}"; do
    TARGET="system_info"
    RESULT="unknown"
    DETAIL="unknown"
    eval "$cmd" && RESULT="success" || RESULT="failed"
    log_message "INFO" "Collecting system info" "command:$cmd" "target:$TARGET" "result:$RESULT"
  done
  show_progress_dialog 15 "Collecting System Information... (15%)"
}

# Collect Process and Network Information
collect_process_network() {
  local proc_dir="${OUTPUT_DIR}/process"
  mkdir -p "$proc_dir" && chmod 700 "$proc_dir"
  local cmds=(
    "ps auxf > $proc_dir/process_list.txt"
    "top -b -n 1 > $proc_dir/top_output.txt"
    "ss -tulnp > $proc_dir/network_connections.txt 2>/dev/null || netstat -tulnp > $proc_dir/network_connections.txt 2>/dev/null"
    "route -n > $proc_dir/route_table.txt 2>/dev/null || ip route > $proc_dir/route_table.txt"
  )
  for cmd in "${cmds[@]}"; do
    TARGET="process_network"
    RESULT="unknown"
    DETAIL="unknown"
    eval "$cmd" && RESULT="success" || RESULT="failed"
    log_message "INFO" "Collecting process/network" "command:$cmd" "target:$TARGET" "result:$RESULT"
  done
  show_progress_dialog 30 "Collecting Process and Network Information... (30%)"
}

# Collect Filesystem Information
collect_filesystem() {
  local fs_dir="${OUTPUT_DIR}/files"
  mkdir -p "$fs_dir" && chmod 700 "$fs_dir"
  local dirs=("/etc" "/var/log" "/home" "/tmp" "/root")
  for dir in "${dirs[@]}"; do
    TARGET="$dir"
    RESULT="unknown"
    DETAIL="unknown"
    dest="${fs_dir}${dir}"
    mkdir -p "$dest"
    cp -a "$dir"/* "$dest" 2>/dev/null && RESULT="success" || RESULT="partial"
    log_message "INFO" "Collecting filesystem" "command:cp -a $dir/* $dest" "target:$TARGET" "result:$RESULT"
  done
  # Find files modified/accessed in the last 7 days
  find / -mtime -7 2>/dev/null > "$fs_dir/recent_modified.txt"
  find / -atime -7 2>/dev/null > "$fs_dir/recent_accessed.txt"
  show_progress_dialog 50 "Collecting Filesystem Information... (50%)"
}

# Collect Users and Permissions Information
collect_users_permissions() {
  local user_dir="${OUTPUT_DIR}/users"
  mkdir -p "$user_dir" && chmod 700 "$user_dir"
  local cmds=(
    "cat /etc/passwd > $user_dir/passwd.txt"
    "cat /etc/group > $user_dir/group.txt"
    "cat /etc/shadow > $user_dir/shadow.txt 2>/dev/null"
    "cat /etc/sudoers > $user_dir/sudoers.txt 2>/dev/null"
    "find / -perm -4000 > $user_dir/suid_files.txt 2>/dev/null"
    "find / -perm -2000 > $user_dir/sgid_files.txt 2>/dev/null"
    "last > $user_dir/login_history.txt 2>/dev/null"
    "lastlog > $user_dir/lastlog.txt 2>/dev/null"
    "w > $user_dir/current_users.txt"
  )
  for cmd in "${cmds[@]}"; do
    TARGET="users_permissions"
    RESULT="unknown"
    DETAIL="unknown"
    eval "$cmd" && RESULT="success" || RESULT="failed"
    log_message "INFO" "Collecting users/permissions" "command:$cmd" "target:$TARGET" "result:$RESULT"
  done
  show_progress_dialog 65 "Collecting Users and Permissions Information... (65%)"
}

# Collect Log Data
collect_logs() {
  local log_dir="${OUTPUT_DIR}/logs"
  mkdir -p "$log_dir" && chmod 700 "$log_dir"
  local log_files=()
  case "$OS_ID" in
    "ubuntu"|"debian")
      log_files=("/var/log/syslog" "/var/log/auth.log")
      ;;
    "centos"|"rhel"|"suse")
      log_files=("/var/log/messages" "/var/log/secure")
      ;;
    *)
      log_files=("/var/log/messages" "/var/log/syslog" "/var/log/secure" "/var/log/auth.log")
      ;;
  esac
  log_files+=("/var/log/dmesg" "/var/log/audit/audit.log")
  for log in "${log_files[@]}"; do
    if [ -f "$log" ]; then
      TARGET="$log"
      RESULT="unknown"
      DETAIL="unknown"
      dest="${log_dir}${log}"
      mkdir -p "$(dirname "$dest")"
      cp -a "$log" "$dest" 2>/dev/null && RESULT="success" || RESULT="failed"
      log_message "INFO" "Collecting log" "command:cp -a $log $dest" "target:$TARGET" "result:$RESULT"
    fi
  done
  show_progress_dialog 80 "Collecting Log Data... (80%)"
}

# Create Disk Image (Deep Mode)
create_disk_image() {
  if [ $DEEP_MODE -eq 0 ]; then
    return
  fi
  local disks=$(lsblk -no NAME,TYPE | grep disk | awk '{print $1}')
  for disk in $disks; do
    TARGET="/dev/$disk"
    RESULT="unknown"
    DETAIL="unknown"
    local img_file="${OUTPUT_DIR}/disk_${disk}.img"
    local cmd="dd if=/dev/$disk of=$img_file bs=4M conv=noerror,sync status=progress 2>/dev/null"
    eval "$cmd" && RESULT="success" || RESULT="failed"
    log_message "INFO" "Creating disk image" "command:$cmd" "target:$TARGET" "result:$RESULT"
    if [ "$RESULT" = "success" ]; then
      md5sum "$img_file" > "${img_file}.md5"
      sha256sum "$img_file" > "${img_file}.sha256"
    fi
  done
  show_progress_dialog 90 "Creating Disk Image... (90%)"
}

# Validate Collected Data
validate_data() {
  local hash_file="${OUTPUT_DIR}/all_files.md5"
  find "$OUTPUT_DIR" -type f -exec md5sum {} + > "$hash_file" 2>/dev/null
  log_message "INFO" "Validating data" "command:find $OUTPUT_DIR -type f -exec md5sum {} +" "target:$OUTPUT_DIR" "result:success"
  show_progress_dialog 95 "Validating Data... (95%)"
}

# Package Data
package_data() {
  local timestamp=$(date +%Y%m%d%H%M%S)
  local tar_file="${OUTPUT_DIR}/forenlinux_data_${timestamp}.tar.gz"
  local exclude="--exclude=${OUTPUT_DIR}/*.tar.gz --exclude=${OUTPUT_DIR}/*.md5 --exclude=${OUTPUT_DIR}/*.sha256"
  local cmd="tar -zcf $tar_file $exclude -C $BASE_DIR output 2>/dev/null"
  TARGET="package_data"
  RESULT="unknown"
  DETAIL="unknown"
  eval "$cmd" && RESULT="success" || RESULT="failed"
  log_message "INFO" "Packaging data" "command:$cmd" "target:$TARGET" "result:$RESULT"
  if [ "$ENCRYPT_PASS" != "" ]; then
    local enc_file="${tar_file}.enc"
    openssl enc -aes-256-cbc -k "$ENCRYPT_PASS" -in "$tar_file" -out "$enc_file" 2>/dev/null
    if [ $? -eq 0 ]; then
      rm "$tar_file"
      log_message "INFO" "Encrypting package" "command:openssl enc" "target:$tar_file" "result:success"
    else
      log_message "ERROR" "Encryption failed" "command:openssl enc" "target:$tar_file" "result:failed"
    fi
  fi
  md5sum "$tar_file" > "${tar_file}.md5" 2>/dev/null
  sha256sum "$tar_file" > "${tar_file}.sha256" 2>/dev/null
  show_progress_dialog 100 "Packaging Data... (100%)"
}

# Generate Report
generate_report() {
  {
    echo "============================== Linux ForenLinux Report =============================="
    echo "1. ForenLinux Overview"
    echo "   ForenLinux ID: FORENLINUX-$(date +%Y%m%d)-001"
    echo "   Operator: $(whoami)"
    echo "   Collection Time: $(date +'%Y-%m-%d %H:%M:%S.%3N')"
    echo "   Target System: $OS_ID $OS_VERSION"
    echo "   Hostname: $(hostname)"
    echo "   Output Path: $OUTPUT_DIR"
    echo "   Collection Mode: $( [ $DEEP_MODE -eq 1 ] && echo 'Deep Mode' || ( [ $QUICK_MODE -eq 1 ] && echo 'Quick Mode' || echo 'Standard Mode' ) )"
    echo ""
    echo "2. Environment Check Results"
    echo "   Privilege Status: $( [ "$EUID" -eq 0 ] && echo 'Root User' || echo 'Non-Root User' )"
    echo "   Dependency Status: $( [ -n "$(check_dependencies)" ] && echo 'Partially Missing' || echo 'Complete' )"
    echo "   Output Directory: Available (Free Space: $(df -h "$OUTPUT_DIR" | awk 'NR==2 {print $4}')）"
    echo ""
    echo "3. Collection Inventory"
    echo "   System Basic Info: $OUTPUT_DIR/system/"
    echo "   Process and Network: $OUTPUT_DIR/process/"
    echo "   Filesystem: $OUTPUT_DIR/files/"
    echo "   Users and Permissions: $OUTPUT_DIR/users/"
    echo "   Log Data: $OUTPUT_DIR/logs/"
    echo ""
    echo "4. Validation Results"
    echo "   Hash Comparison: Completed (See $OUTPUT_DIR/all_files.md5)"
    echo ""
    echo "5. Exception Records"
    echo "   See log at $LOG_DIR/"
    echo ""
    echo "6. Process Logs"
    echo "   See $LOG_DIR/"
    echo ""
    echo "7. Evidence Description"
    echo "   Hash File: $OUTPUT_DIR/all_files.md5"
    echo "   Operation Logs: $LOG_DIR/"
    echo "============================== End of Report =============================="
  } > "$REPORT_FILE"
  chmod 600 "$REPORT_FILE"
  log_message "INFO" "Report generated" "command:generate_report" "target:$REPORT_FILE" "result:success"
}

# Display Summary Information for Initial Analysis
display_summary() {
  if [ $SILENT_MODE -eq 0 ]; then
    echo ""
    echo "============================== ForenLinux Summary Information =============================="
    echo "  System Information:"
    echo "    - OS: $OS_ID $OS_VERSION"
    echo "    - Hostname: $(hostname)"
    echo "    - Collection Time: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "  Collected Categories:"
    if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "system" ]; then
      echo "    - System Basic Info: Collected"
    fi
    if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "process" ] || [ $QUICK_MODE -eq 1 ]; then
      echo "    - Process and Network Info: Collected"
    fi
    if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "files" ] || [ $DEEP_MODE -eq 1 ]; then
      echo "    - Filesystem Info: Collected"
    fi
    if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "user" ]; then
      echo "    - Users and Permissions Info: Collected"
    fi
    if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "log" ] || [ $QUICK_MODE -eq 1 ]; then
      echo "    - Log Data: Collected"
    fi
    if [ $DEEP_MODE -eq 1 ]; then
      echo "    - Disk Image: Collected"
    fi
    echo "  Initial Analysis Tips:"
    echo "    - Check $OUTPUT_DIR/system/ for system details, verify OS version and time."
    echo "    - Review $OUTPUT_DIR/process/network_connections.txt for suspicious network connections."
    echo "    - Examine $OUTPUT_DIR/files/recent_modified.txt for recently modified files."
    echo "    - Analyze $OUTPUT_DIR/users/login_history.txt for unusual login activities."
    echo "    - Inspect $OUTPUT_DIR/logs/ for suspicious log entries."
    echo "  Detailed Information Path: $OUTPUT_DIR"
    echo "  Report File: $REPORT_FILE"
    echo "============================== End of Summary Information =============================="
    echo ""
  fi
  log_message "INFO" "Summary displayed" "command:display_summary" "target:terminal" "result:success"
}

# Performance Control
control_performance() {
  if [ $LOW_PERF_MODE -eq 1 ]; then
    sleep 1  # Reduce collection speed
  fi
}

# Parse Arguments
parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -c|--collect)
        COLLECT_SCOPE="$2"
        shift 2
        ;;
      -o|--output)
        BASE_DIR="$2"
        shift 2
        ;;
      -q|--quick)
        QUICK_MODE=1
        shift
        ;;
      -d|--deep)
        DEEP_MODE=1
        shift
        ;;
      --silent)
        SILENT_MODE=1
        shift
        ;;
      --encrypt-pass)
        ENCRYPT_PASS="$2"
        shift 2
        ;;
      --low-perf)
        LOW_PERF_MODE=1
        shift
        ;;
      --no-progress)
        USE_PROGRESS_BAR=0
        shift
        ;;
      -h|--help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  -c, --collect <scope>   Specify collection scope (all, log, user, etc)"
        echo "  -o, --output <path>     Specify base directory (default: /mnt/forenlinux_<timestamp>)"
        echo "  -q, --quick             Quick mode (core info only)"
        echo "  -d, --deep              Deep mode (full scope + imaging)"
        echo "  --silent                Silent mode (output errors and results only)"
        echo "  --encrypt-pass <pass>   Encrypt packaged file"
        echo "  --low-perf              Low performance mode (reduce resource usage)"
        echo "  --no-progress           Disable progress bar"
         echo "  -h, --help              Show help information"
        exit 0
        ;;
      *)
        shift
        ;;
    esac
  done
}

# Main Function
main() {
  parse_arguments "$@"
  detect_os
  check_privilege
  setup_base_dir
  check_output_dir
  check_dependencies
  log_message "INFO" "Starting ForenLinux collection" "result:started"
  init_progress

  # Execute collection in sequence
  if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "system" ]; then
    collect_system_info
    control_performance
  fi
  if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "process" ] || [ $QUICK_MODE -eq 1 ]; then
    collect_process_network
    control_performance
  fi
  if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "files" ] || [ $DEEP_MODE -eq 1 ]; then
    collect_filesystem
    control_performance
  fi
  if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "user" ]; then
    collect_users_permissions
    control_performance
  fi
  if [ "$COLLECT_SCOPE" = "all" ] || [ "$COLLECT_SCOPE" = "log" ] || [ $QUICK_MODE -eq 1 ]; then
    collect_logs
    control_performance
  fi
  if [ $DEEP_MODE -eq 1 ]; then
    create_disk_image
    control_performance
  fi

  validate_data
  package_data
  generate_report
  display_summary

  log_message "INFO" "ForenLinux collection completed" "result:completed"
  if [ $SILENT_MODE -eq 0 ]; then
    echo "ForenLinux completed, data stored at: $OUTPUT_DIR"
    echo "Report file: $REPORT_FILE"
  fi
}

# Execute Main Function
main "$@"
