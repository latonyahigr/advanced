#!/bin/bash
apt update
apt install -y wget curl unzip tar cron socat
curl https://get.acme.sh | sh
arch=$(arch)
if [[ $arch == "aarch64" || $arch == "arm64" ]]
then
	wget https://sync.optage.moe/node/XrayR_0.9.4_arm64 -O /usr/bin/optxr
else
	wget https://sync.optage.moe/node/XrayR_0.9.4 -O /usr/bin/optxr
fi
chmod +x /usr/bin/optxr
mkdir -p /etc/optxr/
rm -f /etc/systemd/system/optxr@.service
cat > /etc/systemd/system/optxr@.service << EOF
[Unit]
Description=OPTAGE XrayR Service
After=network.target nss-lookup.target
Wants=network.target

[Service]
User=root
Group=root
Type=simple
LimitAS=infinity
LimitRSS=infinity
LimitCORE=infinity
LimitNOFILE=999999
WorkingDirectory=/etc/optxr
ExecStart=/usr/bin/optxr -c %i.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O /etc/optxr/geoip.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O /etc/optxr/geosite.dat
