#!/bin/bash

# Check access to /dev/dri
echo "🔍 Checking GPU device access..."
ls -l /dev/dri || {
    echo "⚠️ /dev/dri not found. Are you running this inside a VM with GPU passthrough?"
    exit 1
}

# Check for renderD128
echo ""
echo "🔍 Looking for 'renderD128' device..."
if [ -e /dev/dri/renderD128 ]; then
    echo "✅ Found renderD128!"
else
    echo "❌ Device 'renderD128' not found. Hardware transcoding may not work."
fi

# Add current user to render group
echo ""
echo "👤 Adding '$USER' to the 'render' group..."
sudo usermod -aG render "$USER" && echo "✅ Done. You may need to log out and back in."

# Install intel-gpu-tools
echo ""
echo "📦 Installing intel-gpu-tools..."
sudo apt update
sudo apt install -y intel-gpu-tools || {
    echo "❌ Failed to install intel-gpu-tools."
    exit 2
}

# Launch intel_gpu_top
echo ""
echo "🚀 Starting intel_gpu_top (press Ctrl+C to exit)..."
sleep 1
sudo intel_gpu_top
