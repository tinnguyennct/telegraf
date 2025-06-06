#!/bin/bash

TELEGRAF_VER="1.31.2-1"
DEB_URL="https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VER}_amd64.deb"
RPM_URL="https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VER}.x86_64.rpm"

VERBOSE_MODE=false
CONFIG_FILE_URL=""

usage() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo " -h, --help           Display this help message"
    echo " -v, --verbose        Enable verbose mode"
    echo " -c, --config URL     Specify a config file URL"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
    echo "${2:-${1#*=}}"
}

handle_options() {
    while [ $# -gt 0 ]; do
        case $1 in
            -h | --help)
                usage
                exit 0
            ;;
            -v | --verbose)
                VERBOSE_MODE=true
            ;;
            -c | --config*)
                if ! has_argument $@; then
                    echo
                    echo "File not specified." >&2
                    usage
                    exit 1
                fi
                CONFIG_FILE_URL=$(extract_argument $@)
                shift
            ;;
            *)
                echo
                echo "Invalid option: $1" >&2
                usage
                exit 1
            ;;
        esac
        shift
    done
}

handle_options "$@"

function exit_with_failure() {
    echo "----------------------------------------"
    tput setaf 1
    echo "[ FAILED ]"
    tput sgr0
    echo "FAILURE: $1" >&2
    echo
    exit 1
}

function command_exists() {
    hash $1 >/dev/null 2>&1
}

clear
echo " ________ ,---.    ,---.    ,-----.    ,---.   .--."
echo "|        ||    \  /    |  .'  .-,  '.  |    \  |  |"
echo "|   .----'|  ,  \/  ,  | / ,-.|  \ _ \ |  ,  \ |  |"
echo "|  _|____ |  |\_   /|  |;  \  '_ /  | :|  |\_ \|  |"
echo "|_( )_   ||  _( )_/ |  ||  _\`,/ \ _/  ||  _( )_\  |"
echo "(_ o._)__|| (_ o _) |  |: (  '\_/ \   ;| (_ o _)  |"
echo "|(_,_)    |  (_,_)  |  | \ \`\"/  \  ) / |  (_,_)\  |"
echo "|   |     |  |      |  |  '. \_/\`\`\".'  |  |    |  |"
echo "'---'     '--'      '--'    '-----'    '--'    '--'"
echo
echo "Telegraf installation script."
echo "----------------------------------------"

if [ $VERBOSE_MODE = true ]; then
    echo "Verbose mode enabled."
    echo "Detecting OS..."
fi
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "${ID}")
elif command_exists lsb_release; then
    OS=$(lsb_release -is)
else
    OS=$(uname -s)
fi
if [ $VERBOSE_MODE = true ]; then
    echo "Detected OS: $OS."
fi
OS=$(echo $OS | tr '[:upper:]' '[:lower:]')
case $OS in
    ubuntu|debian)
        TELEGRAF_URL=$DEB_URL
        PACKAGE=".deb"
        ;;
    centos|centoslinux|rhel|redhatenterpriselinuxserver|fedora|rocky|almalinux)
        TELEGRAF_URL=$RPM_URL
        PACKAGE=".rpm"
        ;;
    *)
        exit_with_failure "Unsupported OS: '$OS'"
        ;;
esac

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Detecting available fetcher..."
fi
if command_exists wget; then
    FETCHER="wget"
elif command_exists curl; then
    FETCHER="curl"
else
    exit_with_failure "Neither 'wget' nor 'curl' command found."
fi
if [ $VERBOSE_MODE = true ]; then
    echo "Detected fetcher: $FETCHER."
fi

case $FETCHER in
    wget)
        OUTPUT_COMMAND="-O telegraf$PACKAGE"
        ;;
    curl)
        OUTPUT_COMMAND="-o telegraf$PACKAGE"
        ;;
esac

cd /tmp || exit_with_failure "Failed to change directory to /tmp."

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Downloading Telegraf..."
    echo
fi
$FETCHER $TELEGRAF_URL $OUTPUT_COMMAND || exit_with_failure "Failed to download Telegraf package."
if [ $VERBOSE_MODE = true ]; then
    echo "Telegraf downloaded at '$(pwd)/telegraf$PACKAGE'."
fi

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Installing Telegraf..."
fi
echo "This script requires superuser access to install packages."
echo "You will be prompted for your password by sudo."
echo
case $OS in
    ubuntu|debian)
        sudo dpkg -i telegraf$PACKAGE || exit_with_failure "Failed to install Telegraf."
        ;;
    centos|centoslinux|rhel|redhatenterpriselinuxserver|fedora|rocky|almalinux)
        sudo rpm -i telegraf$PACKAGE || exit_with_failure "Failed to install Telegraf."
        ;;
esac
if [ $VERBOSE_MODE = true ]; then
    echo "Telegraf installed."
fi

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Configuring Telegraf..."
    echo
fi
case $CONFIG_FILE_URL in
    "")
        echo "No configuration file provided. Will use default configuration."
        ;;
    *)
        case $FETCHER in
            wget)
                OUTPUT_COMMAND="-O telegraf.conf"
                ;;
            curl)
                OUTPUT_COMMAND="-o telegraf.conf"
                ;;
        esac

        $FETCHER $CONFIG_FILE_URL $OUTPUT_COMMAND || exit_with_failure "Failed to download Telegraf configuration file."
        if [ $VERBOSE_MODE = true ]; then
            echo "Telegraf config downloaded at '$(pwd)/telegraf.conf'."
        fi

        sudo cp telegraf.conf /etc/telegraf/telegraf.conf || exit_with_failure "Failed to copy Telegraf configuration file."
        if [ $VERBOSE_MODE = true ]; then
            echo "Telegraf configured."
        fi
        ;;
esac

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Enabling Telegraf Service..."
fi
sudo systemctl restart telegraf && sudo systemctl enable telegraf || exit_with_failure "Failed to restart Telegraf service."
if [ $VERBOSE_MODE = true ]; then
    echo "Telegraf service enabled."
fi

echo "----------------------------------------"
tput setaf 2
echo "[ SUCCESS ]"
tput sgr0
echo "Telegraf has been installed successfully."




current_hostname=$(hostname)

# Lấy địa chỉ IP bắt đầu bằng 10.
ip_address=$(ip addr show | grep -oP '10\.\S+' | cut -d'/' -f1 | head -n 1)

if [ -z "$ip_address" ]; then
    echo "Error: Không tìm thấy địa chỉ IP nào bắt đầu bằng 10."
    exit 1
fi

# Tạo định dạng hostname_IP
new_hostname_value="${current_hostname}_${ip_address}"

# File cần update
config_file="/etc/telegraf/telegraf.conf"

# Kiểm tra xem file có tồn tại không
if [ ! -f "$config_file" ]; then
    echo "Error: File $config_file không tồn tại."
    exit 1
fi

# Backup file gốc
mv "$config_file" "${config_file}.bak"

cat > "$config_file" << EOL
[agent]
  hostname = "$new_hostname_value"
  omit_hostname = false
[[outputs.http]]
  url = "https://frt-vic-sgn-ingest-fmon.prod.fmon.fptcloud.com/insert/0/prometheus/api/v1/write"
  username = "frt-vic"
  password = "ddTYbkPkdXYL6uNS"
  data_format = "prometheusremotewrite"
  [outputs.http.headers]
    Content-Type = "application/x-protobuf"
    Content-Encoding = "snappy"
    X-Prometheus-Remote-Write-Version = "0.1.0"
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  core_tags = false
[[inputs.procstat]]
  pattern = ".*"
  pid_tag = true
  pid_finder = "native"
  [inputs.procstat.tags]
    type = "metric"
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
#[[inputs.x509_cert]]
#  sources = ["{{ ip_address.stdout }}:443"]
[[inputs.diskio]]
[[inputs.kernel]]
[[inputs.mem]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
[[inputs.net]]
[[inputs.netstat]]
EOL

# Thay thế giá trị trong file
sed -i "s/hostname = \"{{ new_hostname }}\"/hostname = \"$new_hostname_value\"/" "$config_file"

echo "Đã cập nhật $config_file, thay đổi hostname thành $new_hostname_value"
echo "File backup được lưu tại ${config_file}.bak"
systemctl restart telegraf
