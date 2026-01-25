#!/bin/bash

################################################################################
#                                                                              #
#  I2P Research Infrastructure - Script 1: System & User Setup                #
#                                                                              #
#  Design by: Siddique Abubakar Muntaka                                       #
#  University of Cincinnati, PhD Information Technology                       #
#  Advisor: Dr. Jacques Bou Abdo                                              #
#  Lab: Center of Anonymity Networks                                          #
#  School of Information Technology                                           #
#                                                                              #
#  Purpose: System updates and research user creation                         #
#                                                                              #
################################################################################

set -e

# Configuration
RESEARCH_USER="sid"
USER_PASSWORD="I2Presearch2025!"  # Change this!

echo "=============================================================================="
echo "  I2P Research Infrastructure Deployment"
echo "  Script 1: System Updates & User Creation"
echo "  Center of Anonymity Networks - University of Cincinnati"
echo "=============================================================================="
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Must run as root"
   exit 1
fi

echo "[1/4] Updating package lists..."
apt update -qq

echo "[2/4] Upgrading system packages..."
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq

echo "[3/4] Creating research user: $RESEARCH_USER"
if id "$RESEARCH_USER" &>/dev/null; then
    echo "  → User already exists, skipping"
else
    useradd -m -s /bin/bash -G sudo "$RESEARCH_USER"
    echo "$RESEARCH_USER:$USER_PASSWORD" | chpasswd
    echo "  → User created with sudo privileges"
fi

echo "[4/4] System summary:"
echo "  OS: $(lsb_release -ds)"
echo "  Kernel: $(uname -r)"
echo "  User: $RESEARCH_USER"
echo "  Disk: $(df -h / | awk 'NR==2 {print $4}') free"
echo "  RAM: $(free -h | awk 'NR==2 {print $7}') available"

echo ""
echo "✓ Script 1 complete - Run 02_desktop_rdp_setup.sh next"
