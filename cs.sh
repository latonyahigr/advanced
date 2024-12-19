#!/bin/bash
set -e  # 如果任何一个命令失败，则立即退出脚本

# 定义变量
XRAYR_INSTALL_SCRIPT="https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh"
CONFIG_REPO="https://github.com/latonyahigr/xrayrwrap.git"  # 使用仓库的克隆URL
COMMIT_HASH="f1321b085cc63d42d086427dc2fbbc225675d995"     # 特定提交的哈希值
SUBDIRECTORY="american"                                    # 子目录名称
CONFIG_DIR="/etc/XrayR"
TMP_DIR="/tmp/xrayr-config"

# 日志记录设置
LOG_FILE="/var/log/install_xrayr.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

# 确保以root身份运行
if [ "$EUID" -ne 0 ]; then 
    echo "请以root身份运行此脚本" >&2
    exit 1
fi

# Step 1: 安装 XrayR
echo "正在安装 XrayR..."
if ! bash <(curl -Ls $XRAYR_INSTALL_SCRIPT); then
    echo "XrayR 安装失败" >&2
    exit 1
fi

# Step 2: 克隆配置文件仓库并切换到指定提交
echo "下载配置文件..."
rm -rf "$TMP_DIR" && git clone --depth 1 --branch "$COMMIT_HASH" "$CONFIG_REPO" "$TMP_DIR" || { echo "克隆配置文件库失败" >&2; exit 1; }

# 检查是否成功切换到了指定的提交
if [ "$(git -C "$TMP_DIR" rev-parse HEAD)" != "$COMMIT_HASH" ]; then
    echo "未能正确切换到指定提交 $COMMIT_HASH" >&2
    exit 1
fi

# 进入子目录前检查子目录是否存在
if [ ! -d "$TMP_DIR/$SUBDIRECTORY" ]; then
    echo "子目录 $SUBDIRECTORY 不存在" >&2
    exit 1
fi

# Step 3: 检查并替换配置文件
echo "检查并替换配置文件..."
mkdir -p "$CONFIG_DIR" && chmod 755 "$CONFIG_DIR" || { echo "创建或设置权限于 $CONFIG_DIR 失败" >&2; exit 1; }

move_config_file() {
    local src=$1
    local dest=$2
    if [ -f "$src" ]; then
        mv "$src" "$dest" && echo "已替换 $(basename $dest) 文件"
    else
        echo "$(basename $src) 文件不存在，请检查" >&2
    fi
}

# 调整路径为克隆后子目录内的路径
move_config_file "$TMP_DIR/$SUBDIRECTORY/custom_outbound.json" "$CONFIG_DIR/custom_outbound.json"
move_config_file "$TMP_DIR/$SUBDIRECTORY/route.json" "$CONFIG_DIR/route.json"

# 清理临时目录
rm -rf "$TMP_DIR"
echo "已清理临时目录 $TMP_DIR"

# Step 4: 写入主配置文件
echo "写入 config.yml 配置..."
cat <<EOF > "$CONFIG_DIR/config.yml"
Log:
  Level: none
  AccessPath: # /etc/XrayR/access.log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: $CONFIG_DIR/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
InboundConfigPath: # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: $CONFIG_DIR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnectionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 30 # Connection idle time limit, Second
  UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB
Nodes:
  -
    PanelType: "V2board"
    ApiConfig:
      ApiHost: "https://tx.xingyun3.com"
      ApiKey: "asdfwer21sdfa13sadf0asd"
      NodeID: 20
      NodeType: V2ray
    ControllerConfig:
      CertConfig:
        CertMode: none
  -
    PanelType: "V2board"
    ApiConfig:
      ApiHost: "https://mqtx.tompoint.online"
      ApiKey: "IICIjANBgkqhkiG9w0BAQEFAAOCA"
      NodeID: 40
      NodeType: V2ray
    ControllerConfig:
      CertConfig:
        CertMode: none
  -
    PanelType: "V2board"
    ApiConfig:
      ApiHost: "https://fftx.afeifeicloud.top"
      ApiKey: "VUu3PUwXdDnZgMe5cDT3"
      NodeID: 27
      NodeType: V2ray
    ControllerConfig:
      CertConfig:
        CertMode: none
  -
    PanelType: "V2board"
    ApiConfig:
      ApiHost: "https://tx.qiyunzero.xyz"
      ApiKey: "4f42e9b78554d3d5a2NTR88YTSh"
      NodeID: 7
      NodeType: V2ray
    ControllerConfig:
      CertConfig:
        CertMode: none
  -
    PanelType: "V2board"
    ApiConfig:
      ApiHost: "https://tx.dengta.store"
      ApiKey: "c9372a7e0a44f8b6790137c645ce"
      NodeID: 8
      NodeType: V2ray
    ControllerConfig:
      CertConfig:
        CertMode: none
  -
    PanelType: "V2board"
    ApiConfig:
      ApiHost: "https://tx.zhousi.link"
      ApiKey: "8g9h0i1j2k3l4m5n6o7p8q9r0s1t2u"
      NodeID: 35
      NodeType: V2ray
    ControllerConfig:
      CertConfig:
        CertMode: none
EOF

# Step 5: 重启 XrayR 服务
echo "重启 XrayR 服务..."
if ! systemctl restart XrayR; then
    echo "重启 XrayR 服务失败" >&2
    exit 1
fi

# Step 6: 安装 BBR
echo "安装 BBR..."
if ! bash <(curl -Ls "https://neko.nnr.moe/ii.sh"); then
    echo "BBR 安装失败" >&2
    exit 1
fi

echo "所有操作完成！"
