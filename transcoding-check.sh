#!/bin/bash

# Resolve the actual logged-in user
USER_NAME=$(logname)

echo "Checking GPU device access..."
if [ -d /dev/dri ]; then
    echo "GPU device path '/dev/dri' is present."
else
    echo "/dev/dri not found. Are you running this inside a VM with GPU passthrough?"
    exit 1
fi

echo ""
echo "Checking for 'renderD128' device..."
if [ -e /dev/dri/renderD128 ]; then
    echo "Found renderD128."
else
    echo "Device 'renderD128' not found. Hardware transcoding requires this device. Aborting."
    exit 2
fi

echo ""
echo "Checking if '$USER_NAME' is in the 'render' group..."
if groups "$USER_NAME" | grep -q render; then
    echo "'$USER_NAME' is already in the render group."
else
    echo "Adding '$USER_NAME' to the 'render' group..."
    sudo usermod -aG render "$USER_NAME" && echo "User added. You may need to log out and back in."
fi

echo ""
echo "Checking if 'vainfo' is installed..."
if command -v vainfo >/dev/null 2>&1; then
    echo "'vainfo' is already installed. Proceeding with VAAPI capability check..."
else
    echo "'vainfo' not found. Installing..."
    sudo apt update
    sudo apt install -y vainfo || {
        echo "Failed to install vainfo."
        exit 3
    }
fi

echo ""
echo "Querying VAAPI capabilities with vainfo..."
vainfo | grep -i 'VAProfile' || {
    echo "No VAAPI profiles detected. Hardware acceleration may not be supported or properly configured."
    exit 4
}

echo ""
echo "Checking if 'intel_gpu_top' is installed for visual feedback..."
if command -v intel_gpu_top >/dev/null 2>&1; then
    echo "'intel_gpu_top' is already installed. Proceeding with snapshot..."
else
    echo "'intel_gpu_top' not found. Installing intel-gpu-tools..."
    sudo apt update
    sudo apt install -y intel-gpu-tools || {
        echo "Failed to install intel-gpu-tools."
        exit 5
    }
fi

echo ""
echo "Launching intel_gpu_top for 2 seconds (visual snapshot)..."
echo "You can press Ctrl+C to interrupt earlier if needed."
sleep 1
sudo timeout 2 intel_gpu_top
