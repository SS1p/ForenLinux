## ForenLinux 使用手册

### 一、功能描述

`ForenLinux.sh` 是一个专为 Linux 系统设计的取证和数据收集工具，旨在帮助用户进行事件响应、数字取证分析以及日常系统审计。脚本以模块化方式收集系统关键信息，并确保数据的完整性和安全性。以下是其核心功能：

- **系统信息收集**：获取操作系统版本、内核信息、主机名、系统时间、时区、CPU 和内存使用情况、磁盘分区及挂载点等基础数据。
- **进程与网络信息收集**：记录当前运行的进程列表、系统资源使用情况（通过 `top`）、网络连接状态及路由表信息。
- **文件系统信息收集**：复制关键目录（如 `/etc`、`/var/log`、`/home`、`/tmp`、`/root`）的内容，并查找最近修改或访问的文件。
- **用户与权限信息收集**：收集用户信息（`/etc/passwd`、`/etc/shadow`）、组信息、sudo 权限配置以及 SUID/SGID 文件列表，记录登录历史和当前在线用户。
- **日志数据收集**：根据操作系统类型（如 Debian、Ubuntu、CentOS 等）收集相关系统日志（如 `/var/log/syslog`、`/var/log/auth.log` 等）。
- **磁盘镜像创建（深度模式）**：在深度模式下，创建完整磁盘镜像文件（`.img` 格式），并生成对应的 MD5 和 SHA256 校验值。
- **数据验证与打包**：对收集的数据生成 MD5 校验值，确保数据完整性，并将所有数据打包为压缩文件（`.tar.gz`），支持加密选项。
- **报告生成**：生成详细的取证报告，包含操作概览、环境检查结果、收集数据清单及校验信息，方便后续分析。
- **进度条显示**：实时显示数据收集进度，帮助用户掌握脚本运行状态。

### 二、创新点

`ForenLinux.sh` 在设计和实现上具有以下创新特点，使其区别于其他取证工具：

1. **模块化与灵活性**：
   - 脚本支持多种收集模式（快速模式、标准模式、深度模式），用户可根据需求选择不同的数据收集范围。
   - 提供 `--collect` 选项，允许用户指定特定的收集范围（如仅收集日志或用户信息），提高效率。

2. **用户友好的进度反馈**：
   - 集成了进度条功能（基于 `dialog` 工具或文本模式），直观显示每个阶段的完成百分比，帮助用户实时了解脚本运行进度。
   - 支持禁用进度条选项，适应不同用户偏好。

3. **数据完整性与安全性**：
   - 自动生成收集数据的 MD5 和 SHA256 校验值，确保数据在收集和传输过程中的完整性。
   - 支持对打包数据进行 AES-256 加密，保护敏感信息，防止未经授权访问。
   - 所有输出目录和文件的权限设置为仅限当前用户访问（`chmod 700` 或 `chmod 600`），增强安全性。

4. **性能优化与兼容性**：
   - 提供低性能模式（`--low-perf`），通过降低运行速度减少资源占用，适用于资源有限的系统。
   - 自动检测操作系统类型（如 Debian、CentOS 等），并根据系统特性调整日志收集策略，确保跨平台兼容性。
   - 动态检查依赖工具，并在缺少工具时提供警告，而不中断运行，增强健壮性。

5. **日志与审计追踪**：
   - 所有操作均记录在详细的日志文件中，包含时间戳、执行命令、目标对象、结果及详细信息，便于审计和问题排查。
   - 日志文件存储在输出目录的 `log` 子目录中，避免权限问题，并确保日志与取证数据一起保存。

### 三、使用方式

#### 1. 前提条件
- **权限要求**：必须以 root 权限运行脚本（使用 `sudo`），以确保访问系统关键文件和执行必要操作。
- **系统环境**：适用于大多数 Linux 发行版（如 Debian、Ubuntu、CentOS 等）。
- **依赖工具**：脚本依赖常见的系统工具（如 `dd`、`md5sum`、`tar` 等），缺少部分工具时脚本仍可运行，但会记录警告。推荐安装 `dialog` 以获得更好的进度条显示效果。
  - 在 Debian/Ubuntu 上安装 `dialog`：`sudo apt update && sudo apt install dialog`
  - 在 CentOS/RHEL 上安装 `dialog`：`sudo yum install dialog`

#### 2. 获取与运行
1. **下载脚本**：将 `ForenLinux.sh` 脚本保存到本地目录（如 `/tool/ForenLinux/`）。
2. **赋予执行权限**：运行 `chmod +x ForenLinux.sh` 以确保脚本可执行。
3. **运行脚本**：使用以下命令以 root 权限运行脚本：
   ```bash
   sudo ./ForenLinux.sh [选项]
   ```

#### 3. 命令行选项
脚本支持多种选项，用户可根据需求自定义运行参数：

- `-c, --collect <scope>`：指定收集范围，可选值包括 `all`（全部，默认）、`system`（系统信息）、`process`（进程与网络）、`files`（文件系统）、`user`（用户与权限）、`log`（日志）。
  - 示例：`sudo ./ForenLinux.sh -c log`（仅收集日志数据）
- `-o, --output <path>`：指定输出基础目录，默认值为 `/mnt/forenlinux_<时间戳>`。
  - 示例：`sudo ./ForenLinux.sh -o /data/forensic`
- `-q, --quick`：快速模式，仅收集核心信息（如进程、网络、日志），适合紧急情况。
  - 示例：`sudo ./ForenLinux.sh -q`
- `-d, --deep`：深度模式，收集完整数据并创建磁盘镜像，适合全面取证。
  - 示例：`sudo ./ForenLinux.sh -d`
- `--silent`：静默模式，仅输出错误和最终结果，减少屏幕输出。
  - 示例：`sudo ./ForenLinux.sh --silent`
- `--encrypt-pass <password>`：对打包的数据文件进行加密，指定加密密码。
  - 示例：`sudo ./ForenLinux.sh --encrypt-pass mypassword`
- `--low-perf`：低性能模式，降低资源占用，适合资源有限的系统。
  - 示例：`sudo ./ForenLinux.sh --low-perf`
- `--no-progress`：禁用进度条显示，适合脚本运行在非交互式环境中。
  - 示例：`sudo ./ForenLinux.sh --no-progress`
- `-h, --help`：显示帮助信息，列出所有可用选项及其说明。
  - 示例：`sudo ./ForenLinux.sh -h`

#### 4. 输出结果与目录结构
脚本运行完成后，数据和报告将存储在指定的输出目录中（默认位于 `/mnt/forenlinux_<时间戳>/output`）。以下是输出目录的结构及其内容的详细描述：

- **基础目录**：`/mnt/forenlinux_<时间戳>/` 或用户指定的目录（如通过 `-o` 选项设置）。
  - **output/**：主输出目录，包含所有取证数据、日志、报告及打包文件。
    - **system/**：存储系统基本信息。
      - `os_release.txt`：操作系统版本信息（来自 `/etc/os-release`）。
      - `kernel_version.txt`：内核版本（来自 `uname -r`）。
      - `hostname.txt`：系统主机名。
      - `system_time.txt`：当前系统时间。
      - `timezone.txt`：系统时区设置。
      - `ntp_status.txt`：NTP 同步状态（如果可用）。
      - `cpu_info.txt`：CPU 信息。
      - `memory_info.txt`：内存使用情况。
      - `disk_partitions.txt`：磁盘分区和布局信息。
      - `mount_points.txt`：挂载点信息。
    - **process/**：存储进程和网络相关信息。
      - `process_list.txt`：当前运行进程列表（来自 `ps auxf`）。
      - `top_output.txt`：系统资源使用快照（来自 `top`）。
      - `network_connections.txt`：网络连接和监听端口信息（来自 `ss` 或 `netstat`）。
      - `route_table.txt`：路由表信息。
    - **files/**：存储文件系统相关数据。
      - `etc/`：`/etc` 目录内容的副本，包含系统配置文件。
      - `var/log/`：`/var/log` 目录内容的副本，包含系统日志。
      - `home/`：`/home` 目录内容的副本，包含用户数据。
      - `tmp/`：`/tmp` 目录内容的副本，包含临时文件。
      - `root/`：`/root` 目录内容的副本，包含 root 用户数据。
      - `recent_modified.txt`：最近 7 天内修改的文件列表。
      - `recent_accessed.txt`：最近 7 天内访问的文件列表。
    - **users/**：存储用户和权限相关信息。
      - `passwd.txt`：用户账户信息（来自 `/etc/passwd`）。
      - `group.txt`：用户组信息（来自 `/etc/group`）。
      - `shadow.txt`：用户密码哈希（来自 `/etc/shadow`，如有权限）。
      - `sudoers.txt`：sudo 权限配置（来自 `/etc/sudoers`，如有权限）。
      - `suid_files.txt`：具有 SUID 权限的文件列表。
      - `sgid_files.txt`：具有 SGID 权限的文件列表。
      - `login_history.txt`：用户登录历史记录（来自 `last`）。
      - `lastlog.txt`：用户最后登录信息（来自 `lastlog`）。
      - `current_users.txt`：当前在线用户（来自 `w`）。
    - **logs/**：存储系统日志文件的副本。
      - 具体文件根据操作系统类型不同而异，如 `syslog`、`auth.log`（Debian/Ubuntu）或 `messages`、`secure`（CentOS/RHEL）。
      - 其他常见日志，如 `dmesg` 或 `audit.log`（如果存在）。
    - **log/**：存储脚本运行日志。
      - `forenlinux_log_<日期_小时>.log`：脚本执行的详细日志，包含时间戳、操作命令、目标、结果等信息。
    - **disk_<device>.img**（深度模式下）：磁盘镜像文件，文件名根据设备名称生成（如 `disk_sda.img`）。
    - **disk_<device>.img.md5** 和 **disk_<device>.img.sha256**（深度模式下）：磁盘镜像的校验值文件。
    - **all_files.md5**：所有收集文件的 MD5 校验值，用于数据完整性验证。
    - **forenlinux_data_<时间戳>.tar.gz**：所有取证数据的压缩包，若启用加密则为 `.enc` 文件。
    - **forenlinux_data_<时间戳>.tar.gz.md5** 和 **forenlinux_data_<时间戳>.tar.gz.sha256**：压缩包的校验值文件。
    - **forenlinux_report_<时间戳>.txt**：取证报告文件，包含操作概览、环境检查结果及数据清单。

#### 5. 运行示例
- **标准模式运行**（默认，收集所有数据）：
  ```bash
  sudo ./ForenLinux.sh
  ```
  输出示例：
  ```
  ForenLinux completed, data stored at: /mnt/forenlinux_20251027124108/output
  Report file: /mnt/forenlinux_20251027124108/output/forenlinux_report_20251027124108.txt
  ```

- **快速模式运行**（仅收集核心信息）：
  ```bash
  sudo ./ForenLinux.sh -q
  ```

- **指定输出目录并加密**：
  ```bash
  sudo ./ForenLinux.sh -o /data/forensic --encrypt-pass mypassword
  ```

#### 6. 注意事项
- **权限问题**：确保输出目录有足够的写入权限，否则脚本会报错并退出。
- **磁盘空间**：深度模式下创建磁盘镜像需要大量空间，请确保输出目录所在分区有足够容量。
- **运行时间**：根据模式和系统数据量，运行时间可能从几分钟到数小时不等，进度条可帮助您估算剩余时间。
- **加密数据恢复**：若使用加密选项，请妥善保存密码，丢失密码将无法解密数据。解密命令示例：
  ```bash
  openssl enc -aes-256-cbc -d -k mypassword -in forenlinux_data_<时间戳>.tar.gz.enc -out forenlinux_data_<时间戳>.tar.gz
  ```
