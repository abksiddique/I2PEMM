#!/bin/bash

################################################################################
#                                                                              #
#  I2P Research Infrastructure - Script 2: Desktop & Remote Access            #
#                                                                              #
#  Design by: Siddique Abubakar Muntaka                                       #
#  University of Cincinnati, PhD Information Technology                       #
#  Advisor: Dr. Jacques Bou Abdo                                              #
#  Lab: Center of Anonymity Networks                                          #
#  School of Information Technology                                           #
#                                                                              #
#  Purpose: Install XFCE desktop, Firefox, and xrdp for remote access         #
#                                                                              #
################################################################################

set -e

RESEARCH_USER="sid"

echo "=============================================================================="
echo "  I2P Research Infrastructure Deployment"
echo "  Script 2: Desktop Environment & RDP Setup"
echo "  Center of Anonymity Networks - University of Cincinnati"
echo "=============================================================================="
echo ""

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Must run as root"
   exit 1
fi

echo "[1/4] Installing XFCE desktop environment..."
DEBIAN_FRONTEND=noninteractive apt install -y -qq xfce4 xfce4-goodies

echo "[2/4] Installing Firefox browser..."
DEBIAN_FRONTEND=noninteractive apt install -y -qq firefox

echo "[3/4] Installing and configuring xrdp..."
DEBIAN_FRONTEND=noninteractive apt install -y -qq xrdp

# Configure XFCE for xrdp
echo "startxfce4" > /home/$RESEARCH_USER/.xsession
chown $RESEARCH_USER:$RESEARCH_USER /home/$RESEARCH_USER/.xsession

echo "[4/4] Verifying services..."
systemctl enable xrdp --quiet
systemctl restart xrdp

echo ""
echo "✓ Script 2 complete"
echo "  → RDP: Port 3389 (firewall not opened yet)"
echo "  → Browser: Firefox installed"
echo "  → Desktop: XFCE configured"
echo ""
echo "Run 03_firewall_setup.sh next"
