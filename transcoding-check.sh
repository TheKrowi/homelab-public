#!/bin/bash

# Resolve the actual logged-in user
USER_NAME=$(logname)

# Check access to /dev/dri
echo "Checking GPU device access..."
ls -l /dev/dri || {
    echo "/dev/dri not found. Are you running this inside a VM with GPU passthrough?"
    exit 1
}

# Strict check for renderD128
echo ""
echo "Checking for 'renderD128' device..."
if [ -e /dev/dri/renderD128 ]; then
    echo "Found renderD128."
else
    echo "Device 'renderD128' not found. Hardware transcoding requires this device. Aborting."
    exit 1
fi

# Add the user to the render group if not already in it
echo ""
echo "Checking if '$USER_NAME' is in the 'render' group..."
if groups "$USER_NAME" | grep -q render; then
    echo "'$USER_NAME' is already in the render group."
else
    echo "Adding '$USER_NAME' to the 'render' group..."
    sudo usermod -aG render "$USER_NAME" && echo "User added. You may need to log out and back in."
fi

# Install intel-gpu-tools
echo ""
echo "Installing intel-gpu-tools..."
sudo apt update
sudo apt install -y intel-gpu-tools || {
    echo "Failed to install intel-gpu-tools."
    exit 2
}

# Confirm intel_gpu_top is available
echo ""
command -v intel_gpu_top >/dev/null 2>&1 || {
    echo "intel_gpu_top was not found after install. Please check your drivers."
    exit 3
}

# Launch intel_gpu_top
echo "Starting intel_gpu_top (press Ctrl+C to exit)..."
sleep 1
sudo intel_gpu_top
