#!/bin/sh

# Exit on error
set -e

echo "📦 Updating Alpine and installing required packages..."
apk update
apk add git bash sqlite sudo wget openrc

echo "👤 Creating Gitea user and data directories..."
adduser -D -g 'Gitea' gitea
mkdir -p /home/gitea/data
chown -R gitea:gitea /home/gitea

echo "⬇️ Downloading latest Gitea binary..."
wget -O /usr/local/bin/gitea https://dl.gitea.io/gitea/latest/gitea-linux-arm64
chmod +x /usr/local/bin/gitea

echo "📂 Creating OpenRC service for Gitea..."
cat << 'EOF' > /etc/init.d/gitea
#!/sbin/openrc-run

name="Gitea"
description="Lightweight Git server"
command="/usr/local/bin/gitea"
command_args="web"
command_background="yes"
pidfile="/var/run/gitea.pid"
user="gitea"
group="gitea"
EOF

chmod +x /etc/init.d/gitea

echo "🔁 Enabling Gitea service on boot..."
rc-update add gitea default

echo "🚀 Starting Gitea now..."
service gitea start

echo "✅ Gitea should now be running at http://<VM-IP>:3000"
