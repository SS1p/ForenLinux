## ForenLinux User Manual

### I. Functional Description

`ForenLinux.sh` is a forensic and data collection tool designed for Linux systems, aimed at assisting users with incident response, digital forensic analysis, and routine system auditing. The script collects critical system information in a modular way while ensuring data integrity and security. Below are its core functionalities:

- **System Information Collection**: Gathers basic data such as operating system version, kernel information, hostname, system time, timezone, CPU and memory usage, disk partitions, and mount points.
- **Process and Network Information Collection**: Records the list of currently running processes, system resource usage (via `top`), network connection status, and routing table information.
- **Filesystem Information Collection**: Copies contents of key directories (e.g., `/etc`, `/var/log`, `/home`, `/tmp`, `/root`) and identifies recently modified or accessed files.
- **User and Permission Information Collection**: Collects user information (`/etc/passwd`, `/etc/shadow`), group information, sudo permission configurations, SUID/SGID file lists, login history, and currently active users.
- **Log Data Collection**: Collects relevant system logs (e.g., `/var/log/syslog`, `/var/log/auth.log`) based on the operating system type (Debian, Ubuntu, CentOS, etc.).
- **Disk Image Creation (Deep Mode)**: Creates complete disk image files (`.img` format) in deep mode, along with corresponding MD5 and SHA256 checksums.
- **Data Validation and Packaging**: Generates MD5 checksums for collected data to ensure integrity, and packages all data into a compressed file (`.tar.gz`) with optional encryption.
- **Report Generation**: Produces a detailed forensic report including an overview of operations, environment check results, collected data inventory, and validation information for subsequent analysis.
- **Progress Bar Display**: Shows real-time progress of data collection, helping users track the script's execution status.

### II. Innovative Features

`ForenLinux.sh` stands out from other forensic tools due to the following innovative features in its design and implementation:

1. **Modularity and Flexibility**:
   - The script supports multiple collection modes (Quick Mode, Standard Mode, Deep Mode), allowing users to choose different data collection scopes based on their needs.
   - Provides the `--collect` option, enabling users to specify particular collection scopes (e.g., logs or user information only), improving efficiency.

2. **User-Friendly Progress Feedback**:
   - Integrates a progress bar feature (based on the `dialog` tool or text mode), visually displaying the completion percentage of each stage, helping users monitor progress in real-time.
   - Supports an option to disable the progress bar to accommodate different user preferences.

3. **Data Integrity and Security**:
   - Automatically generates MD5 and SHA256 checksums for collected data, ensuring integrity during collection and transfer.
   - Supports AES-256 encryption for packaged data, protecting sensitive information from unauthorized access.
   - Sets permissions for all output directories and files to be accessible only by the current user (`chmod 700` or `chmod 600`), enhancing security.

4. **Performance Optimization and Compatibility**:
   - Offers a low-performance mode (`--low-perf`) to reduce resource usage by slowing down execution, suitable for systems with limited resources.
   - Automatically detects the operating system type (e.g., Debian, CentOS) and adjusts log collection strategies accordingly, ensuring cross-platform compatibility.
   - Dynamically checks for dependent tools and provides warnings without interrupting execution if tools are missing, enhancing robustness.

5. **Logging and Audit Tracking**:
   - Records all operations in detailed log files, including timestamps, executed commands, targets, results, and detailed information for auditing and troubleshooting.
   - Stores log files in the `log` subdirectory of the output directory, avoiding permission issues and ensuring logs are saved alongside forensic data.

### III. Usage Instructions

#### 1. Prerequisites
- **Permission Requirements**: The script must be run with root privileges (using `sudo`) to ensure access to critical system files and perform necessary operations.
- **System Environment**: Compatible with most Linux distributions (e.g., Debian, Ubuntu, CentOS).
- **Dependent Tools**: The script relies on common system tools (e.g., `dd`, `md5sum`, `tar`). It can still run if some tools are missing, but warnings will be logged. Installing `dialog` is recommended for a better progress bar display.
  - Install `dialog` on Debian/Ubuntu: `sudo apt update && sudo apt install dialog`
  - Install `dialog` on CentOS/RHEL: `sudo yum install dialog`

#### 2. Acquisition and Execution
1. **Download the Script**: Save the `ForenLinux.sh` script to a local directory (e.g., `/tool/ForenLinux/`).
2. **Grant Execution Permission**: Run `chmod +x ForenLinux.sh` to ensure the script is executable.
3. **Run the Script**: Execute the script with root privileges using the following command:
   ```bash
   sudo ./ForenLinux.sh [options]
   ```

#### 3. Command-Line Options
The script supports various options, allowing users to customize runtime parameters based on their needs:

- `-c, --collect <scope>`: Specifies the collection scope. Options include `all` (everything, default), `system` (system information), `process` (processes and network), `files` (filesystem), `user` (users and permissions), `log` (logs).
  - Example: `sudo ./ForenLinux.sh -c log` (collect logs only)
- `-o, --output <path>`: Specifies the base output directory. The default is `/mnt/forenlinux_<timestamp>`.
  - Example: `sudo ./ForenLinux.sh -o /data/forensic`
- `-q, --quick`: Quick mode, collects only core information (e.g., processes, network, logs), suitable for urgent situations.
  - Example: `sudo ./ForenLinux.sh -q`
- `-d, --deep`: Deep mode, collects comprehensive data and creates disk images, suitable for thorough forensics.
  - Example: `sudo ./ForenLinux.sh -d`
- `--silent`: Silent mode, outputs only errors and final results, reducing screen output.
  - Example: `sudo ./ForenLinux.sh --silent`
- `--encrypt-pass <password>`: Encrypts the packaged data file with the specified password.
  - Example: `sudo ./ForenLinux.sh --encrypt-pass mypassword`
- `--low-perf`: Low-performance mode, reduces resource usage, suitable for systems with limited resources.
  - Example: `sudo ./ForenLinux.sh --low-perf`
- `--no-progress`: Disables the progress bar display, suitable for non-interactive environments.
  - Example: `sudo ./ForenLinux.sh --no-progress`
- `-h, --help`: Displays help information, listing all available options and their descriptions.
  - Example: `sudo ./ForenLinux.sh -h`

#### 4. Output Results and Directory Structure
After the script completes, data and reports are stored in the specified output directory (default location: `/mnt/forenlinux_<timestamp>/output`). Below is the structure of the output directory and a detailed description of its contents:

- **Base Directory**: `/mnt/forenlinux_<timestamp>/` or a user-specified directory (set via the `-o` option).
  - **output/**: Main output directory containing all forensic data, logs, reports, and packaged files.
    - **system/**: Stores basic system information.
      - `os_release.txt`: Operating system version information (from `/etc/os-release`).
      - `kernel_version.txt`: Kernel version (from `uname -r`).
      - `hostname.txt`: System hostname.
      - `system_time.txt`: Current system time.
      - `timezone.txt`: System timezone settings.
      - `ntp_status.txt`: NTP synchronization status (if available).
      - `cpu_info.txt`: CPU information.
      - `memory_info.txt`: Memory usage information.
      - `disk_partitions.txt`: Disk partition and layout information.
      - `mount_points.txt`: Mount point information.
    - **process/**: Stores process and network-related information.
      - `process_list.txt`: List of currently running processes (from `ps auxf`).
      - `top_output.txt`: Snapshot of system resource usage (from `top`).
      - `network_connections.txt`: Network connections and listening ports (from `ss` or `netstat`).
      - `route_table.txt`: Routing table information.
    - **files/**: Stores filesystem-related data.
      - `etc/` : Copy of the `/etc` directory contents, including system configuration files.
      - `var/log/` : Copy of the `/var/log` directory contents, including system logs.
      - `home/` : Copy of the `/home` directory contents, including user data.
      - `tmp/` : Copy of the `/tmp` directory contents, including temporary files.
      - `root/` : Copy of the `/root` directory contents, including root user data.
      - `recent_modified.txt`: List of files modified within the last 7 days.
      - `recent_accessed.txt`: List of files accessed within the last 7 days.
    - **users/**: Stores user and permission-related information.
      - `passwd.txt`: User account information (from `/etc/passwd`).
      - `group.txt`: User group information (from `/etc/group`).
      - `shadow.txt`: User password hashes (from `/etc/shadow`, if accessible).
      - `sudoers.txt`: Sudo permission configurations (from `/etc/sudoers`, if accessible).
      - `suid_files.txt`: List of files with SUID permissions.
      - `sgid_files.txt`: List of files with SGID permissions.
      - `login_history.txt`: User login history (from `last`).
      - `lastlog.txt`: Last login information for users (from `lastlog`).
      - `current_users.txt`: Currently active users (from `w`).
    - **logs/**: Stores copies of system log files.
      - Specific files vary by operating system type, such as `syslog`, `auth.log` (Debian/Ubuntu) or `messages`, `secure` (CentOS/RHEL).
      - Other common logs, such as `dmesg` or `audit.log` (if present).
    - **log/**: Stores script execution logs.
      - `forenlinux_log_<date_hour>.log`: Detailed logs of script execution, including timestamps, executed commands, targets, results, and details.
    - **disk_<device>.img** (Deep Mode): Disk image file, named based on the device (e.g., `disk_sda.img`).
    - **disk_<device>.img.md5** and **disk_<device>.img.sha256** (Deep Mode): Checksum files for the disk image.
    - **all_files.md5**: MD5 checksums of all collected files for data integrity verification.
    - **forenlinux_data_<timestamp>.tar.gz**: Compressed package of all forensic data; if encryption is enabled, it becomes a `.enc` file.
    - **forenlinux_data_<timestamp>.tar.gz.md5** and **forenlinux_data_<timestamp>.tar.gz.sha256**: Checksum files for the compressed package.
    - **forenlinux_report_<timestamp>.txt**: Forensic report file containing an overview of operations, environment check results, and data inventory.

#### 5. Usage Examples
- **Standard Mode Execution** (default, collects all data):
  ```bash
  sudo ./ForenLinux.sh
  ```
  Output Example:
  ```
  ForenLinux completed, data stored at: /mnt/forenlinux_20251027124108/output
  Report file: /mnt/forenlinux_20251027124108/output/forenlinux_report_20251027124108.txt
  ```

- **Quick Mode Execution** (collects only core information):
  ```bash
  sudo ./ForenLinux.sh -q
  ```

- **Specify Output Directory and Enable Encryption**:
  ```bash
  sudo ./ForenLinux.sh -o /data/forensic --encrypt-pass mypassword
  ```

#### 6. Notes
- **Permission Issues**: Ensure the output directory has sufficient write permissions; otherwise, the script will report an error and exit.
- **Disk Space**: Creating disk images in deep mode requires significant space; ensure the output directory's partition has enough capacity.
- **Execution Time**: Depending on the mode and system data volume, execution time may range from a few minutes to several hours. The progress bar helps estimate remaining time.
- **Encrypted Data Recovery**: If encryption is used, securely store the password. Losing the password will prevent decryption. Decryption command example:
  ```bash
  openssl enc -aes-256-cbc -d -k mypassword -in forenlinux_data_<timestamp>.tar.gz.enc -out forenlinux_data_<timestamp>.tar.gz
  ```

### IV. Language Switch
 - 点击 --->  zh_CN[简体中文](readme/README.zh_CN.md)
---
