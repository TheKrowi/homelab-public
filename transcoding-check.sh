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
    exit 2
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

echo ""
echo "Checking if intel_gpu_top is already installed..."
if command -v intel_gpu_top >/dev/null 2>&1; then
    echo "intel_gpu_top is already installed. Skipping installation."
else
    echo "intel_gpu_top not found. Installing intel-gpu-tools..."
    sudo apt update
    sudo apt install -y intel-gpu-tools || {
        echo "Failed to install intel-gpu-tools."
        exit 3
    }
fi

# Confirm intel_gpu_top is available
echo ""
command -v intel_gpu_top >/dev/null 2>&1 || {
    echo "intel_gpu_top was not found after install. Please check your drivers."
    exit 4
}

# Run intel_gpu_top for 2 seconds and capture output
sudo timeout 2 intel_gpu_top > /tmp/gpu_sample.txt 2>&1

# Show snapshot
echo ""
echo "----- GPU Activity Snapshot -----"
head -n 20 /tmp/gpu_sample.txt
echo "---------------------------------"

# Check for GPU activity in the output
echo ""
echo "Checking for signs of GPU activity (Video Decode section)..."
if grep -qi "Video" /tmp/gpu_sample.txt; then
    echo "GPU metrics detected. Transcoding-capable GPU is active."
else
    echo "No visible GPU metrics during sample. Is transcoding software running?"
fi
