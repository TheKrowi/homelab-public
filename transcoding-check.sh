#!/bin/bash

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Resolve the actual logged-in user
USER_NAME=$(logname)

# Status flags
STATUS_DRI=false
STATUS_RENDER=false
STATUS_GROUP=false
STATUS_GROUP_ADDED=false
STATUS_VAINFO=false
STATUS_VAINFO_INSTALLED=false
STATUS_VAAPI_PROFILES=false
STATUS_GPU_TOP=false
STATUS_GPU_TOP_INSTALLED=false

echo -e "${YELLOW}Step 1: Checking GPU device access...${NC}"
if [ -d /dev/dri ]; then
    echo -e "${GREEN}✔ GPU device path '/dev/dri' is present.${NC}"
    STATUS_DRI=true
else
    echo -e "${RED}✖ '/dev/dri' not found. Are you running this inside a VM with GPU passthrough?${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Step 2: Checking for 'renderD128' device...${NC}"
if [ -e /dev/dri/renderD128 ]; then
    echo -e "${GREEN}✔ Found 'renderD128'.${NC}"
    STATUS_RENDER=true
else
    echo -e "${RED}✖ Device 'renderD128' not found. Hardware transcoding requires this device. Aborting.${NC}"
    exit 2
fi

echo -e "\n${YELLOW}Step 3: Verifying group membership...${NC}"
if groups "$USER_NAME" | grep -q render; then
    echo -e "${GREEN}✔ '$USER_NAME' is already in the 'render' group.${NC}"
    STATUS_GROUP=true
else
    echo -e "${YELLOW}➤ Adding '$USER_NAME' to the 'render' group...${NC}"
    sudo usermod -aG render "$USER_NAME" && {
        echo -e "${GREEN}✔ User added to 'render' group. You may need to log out and back in.${NC}"
        STATUS_GROUP=true
        STATUS_GROUP_ADDED=true
    }
fi

echo -e "\n${YELLOW}Step 4: Checking for 'vainfo' utility...${NC}"
if command -v vainfo >/dev/null 2>&1; then
    echo -e "${GREEN}✔ 'vainfo' is already installed.${NC}"
    STATUS_VAINFO=true
else
    echo -e "${YELLOW}➤ Installing 'vainfo'...${NC}"
    sudo apt update
    sudo apt install -y vainfo && {
        echo -e "${GREEN}✔ 'vainfo' installed.${NC}"
        STATUS_VAINFO=true
        STATUS_VAINFO_INSTALLED=true
    } || {
        echo -e "${RED}✖ Failed to install 'vainfo'.${NC}"
        exit 3
    }
fi

echo -e "\n${YELLOW}Step 5: Querying VAAPI capabilities...${NC}"
if vainfo | grep -i 'VAProfile' >/dev/null 2>&1; then
    echo -e "${GREEN}✔ VAAPI profiles detected — transcoding-capable codecs available.${NC}"
    STATUS_VAAPI_PROFILES=true
else
    echo -e "${RED}✖ No VAAPI profiles detected. Hardware acceleration may not be supported or configured.${NC}"
    exit 4
fi

echo -e "\n${YELLOW}Step 6: Checking for 'intel_gpu_top'...${NC}"
if command -v intel_gpu_top >/dev/null 2>&1; then
    echo -e "${GREEN}✔ 'intel_gpu_top' is already installed.${NC}"
    STATUS_GPU_TOP=true
else
    echo -e "${YELLOW}➤ Installing 'intel_gpu_top' via intel-gpu-tools...${NC}"
    sudo apt update
    sudo apt install -y intel-gpu-tools && {
        echo -e "${GREEN}✔ 'intel_gpu_top' installed.${NC}"
        STATUS_GPU_TOP=true
        STATUS_GPU_TOP_INSTALLED=true
    } || {
        echo -e "${RED}✖ Failed to install intel-gpu-tools.${NC}"
        exit 5
    }
fi

echo -e "\n${YELLOW}Step 7: Launching visual GPU snapshot...${NC}"
echo -e "${YELLOW}➤ Running intel_gpu_top for 2 seconds. You can press Ctrl+C to interrupt earlier.${NC}"
sleep 1
STATUS_GPU_TOP=true
sudo timeout 2 intel_gpu_top

# Final Summary
echo -e "\n${YELLOW}===== Transcoding Readiness Summary =====${NC}"

echo -e "GPU Path (/dev/dri)..................: $([ "$STATUS_DRI" = true ] && echo "${GREEN}✔ Present${NC}" || echo "${RED}✖ Missing${NC}")"
echo -e "Device renderD128....................: $([ "$STATUS_RENDER" = true ] && echo "${GREEN}✔ Found${NC}" || echo "${RED}✖ Not Found${NC}")"
echo -e "User in 'render' group...............: $([ "$STATUS_GROUP" = true ] && echo "${GREEN}✔ Yes${NC}" || echo "${RED}✖ No${NC}")"
echo -e "Render group was added...............: $([ "$STATUS_GROUP_ADDED" = true ] && echo "${YELLOW}➤ Added during check${NC}" || echo "${GREEN}✔ Already present${NC}")"
echo -e "'vainfo' installed...................: $([ "$STATUS_VAINFO" = true ] && echo "${GREEN}✔ Yes${NC}" || echo "${RED}✖ No${NC}")"
echo -e "vainfo installed during script.......: $([ "$STATUS_VAINFO_INSTALLED" = true ] && echo "${YELLOW}➤ Installed${NC}" || echo "${GREEN}✔ Already present${NC}")"
echo -e "VAAPI profiles available.............: $([ "$STATUS_VAAPI_PROFILES" = true ] && echo "${GREEN}✔ Detected${NC}" || echo "${RED}✖ None${NC}")"
echo -e "intel_gpu_top installed..............: $([ "$STATUS_GPU_TOP" = true ] && echo "${GREEN}✔ Yes${NC}" || echo "${RED}✖ No${NC}")"
echo -e "intel_gpu_top installed during check.: $([ "$STATUS_GPU_TOP_INSTALLED" = true ] && echo "${YELLOW}➤ Installed${NC}" || echo "${GREEN}✔ Already present${NC}")"
echo -e "Visual GPU snapshot shown............: ${GREEN}✔ Snapshot complete${NC}"

echo -e "${YELLOW}==========================================${NC}"
