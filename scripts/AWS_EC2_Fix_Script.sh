#!/bin/bash

##############################################################################
# AWS EC2 Instance SSH & I2P Network Configuration Fix
# 
# Purpose: Automatically configure SSH password authentication and fix I2P
#          firewall/network issues on AWS EC2 Ubuntu instances
#
# Problem Solved: 
#   1. AWS EC2 blocks password SSH by default (only allows key-based)
#   2. I2P routers show "Firewalled" status due to misconfigured networking
#   3. Cloud-init config files override manual SSH settings
#
# Usage: Run this script via AWS EC2 Instance Connect or Systems Manager
#        after initial deployment of I2P research infrastructure
#
# Design by: Siddique Abubakar Muntaka
# University of Cincinnati - PhD Information Technology
# Advisor: Dr. Jacques Bou Abdo
# Lab: Center of Anonymity Networks
# School of Information Technology
##############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
I2P_USER="sid"
I2P_CONFIG_DIR="/home/${I2P_USER}/.i2p"
ROUTER_CONFIG="${I2P_CONFIG_DIR}/router.config"
SSH_MAIN_CONFIG="/etc/ssh/sshd_config"
SSH_CLOUD_CONFIG="/etc/ssh/sshd_config.d/60-cloudimg-settings.conf"
BACKUP_DIR="/root/aws-fix-backups-$(date +%Y%m%d_%H%M%S)"

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                                              ║${NC}"
    echo -e "${BLUE}║  ${GREEN}AWS EC2 SSH & I2P Network Configuration Fix${BLUE}                               ║${NC}"
    echo -e "${BLUE}║                                                                              ║${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}Automatically resolves SSH authentication and I2P firewall issues${BLUE}      ║${NC}"
    echo -e "${BLUE}║                                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Design by: Siddique Abubakar Muntaka${NC}"
    echo -e "${CYAN}Center of Anonymity Networks - University of Cincinnati${NC}"
    echo -e "${CYAN}Advisor: Dr. Jacques Bou Abdo${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[Step $1/$2] $3${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}  → $1${NC}"
}

##############################################################################
# Verification Functions
##############################################################################

verify_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        echo -e "${YELLOW}Please run: sudo bash $0${NC}"
        exit 1
    fi
}

verify_i2p_user_exists() {
    if ! id "$I2P_USER" >/dev/null 2>&1; then
        print_warning "User '$I2P_USER' does not exist"
        print_info "Creating user '$I2P_USER'..."
        useradd -m -s /bin/bash "$I2P_USER"
        print_success "User '$I2P_USER' created"
    else
        print_success "User '$I2P_USER' exists"
    fi
}

##############################################################################
# Backup Functions
##############################################################################

create_backups() {
    print_section "CREATING CONFIGURATION BACKUPS"
    
    print_step "1" "2" "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    print_success "Backup directory: $BACKUP_DIR"
    
    print_step "2" "2" "Backing up SSH configurations..."
    
    # Backup main SSH config
    if [ -f "$SSH_MAIN_CONFIG" ]; then
        cp "$SSH_MAIN_CONFIG" "${BACKUP_DIR}/sshd_config.backup"
        print_success "Backed up: sshd_config"
    fi
    
    # Backup cloud-init SSH config if exists
    if [ -f "$SSH_CLOUD_CONFIG" ]; then
        cp "$SSH_CLOUD_CONFIG" "${BACKUP_DIR}/60-cloudimg-settings.conf.backup"
        print_success "Backed up: 60-cloudimg-settings.conf"
    fi
    
    # Backup I2P router config if exists
    if [ -f "$ROUTER_CONFIG" ]; then
        cp "$ROUTER_CONFIG" "${BACKUP_DIR}/router.config.backup"
        print_success "Backed up: router.config"
    fi
}

##############################################################################
# SSH Configuration Functions
##############################################################################

detect_ssh_service() {
    print_section "DETECTING SSH SERVICE"
    
    print_step "1" "1" "Identifying SSH service name..."
    
    if systemctl list-units --type=service | grep -q "ssh.service"; then
        SSH_SERVICE="ssh"
        print_success "SSH service: ssh.service (Ubuntu/Debian style)"
    elif systemctl list-units --type=service | grep -q "sshd.service"; then
        SSH_SERVICE="sshd"
        print_success "SSH service: sshd.service (CentOS/RHEL style)"
    else
        print_error "Could not detect SSH service"
        exit 1
    fi
}

fix_main_ssh_config() {
    print_section "FIXING MAIN SSH CONFIGURATION"
    
    print_step "1" "4" "Enabling password authentication..."
    
    # Enable PasswordAuthentication
    if grep -q "^PasswordAuthentication" "$SSH_MAIN_CONFIG"; then
        sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$SSH_MAIN_CONFIG"
    else
        echo "PasswordAuthentication yes" >> "$SSH_MAIN_CONFIG"
    fi
    
    # Uncomment if commented
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' "$SSH_MAIN_CONFIG"
    sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' "$SSH_MAIN_CONFIG"
    
    print_success "PasswordAuthentication enabled"
    
    print_step "2" "4" "Enabling ChallengeResponseAuthentication..."
    
    if grep -q "^ChallengeResponseAuthentication" "$SSH_MAIN_CONFIG"; then
        sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' "$SSH_MAIN_CONFIG"
    else
        echo "ChallengeResponseAuthentication yes" >> "$SSH_MAIN_CONFIG"
    fi
    
    sed -i 's/^#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' "$SSH_MAIN_CONFIG"
    
    print_success "ChallengeResponseAuthentication enabled"
    
    print_step "3" "4" "Enabling KbdInteractiveAuthentication..."
    
    if grep -q "^KbdInteractiveAuthentication" "$SSH_MAIN_CONFIG"; then
        sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' "$SSH_MAIN_CONFIG"
    else
        echo "KbdInteractiveAuthentication yes" >> "$SSH_MAIN_CONFIG"
    fi
    
    print_success "KbdInteractiveAuthentication enabled"
    
    print_step "4" "4" "Ensuring UsePAM is enabled..."
    
    if grep -q "^UsePAM" "$SSH_MAIN_CONFIG"; then
        sed -i 's/^UsePAM.*/UsePAM yes/' "$SSH_MAIN_CONFIG"
    else
        echo "UsePAM yes" >> "$SSH_MAIN_CONFIG"
    fi
    
    print_success "UsePAM enabled"
}

fix_cloud_init_ssh_override() {
    print_section "FIXING AWS CLOUD-INIT SSH OVERRIDE"
    
    print_step "1" "3" "Checking for cloud-init config directory..."
    
    if [ -d "/etc/ssh/sshd_config.d" ]; then
        print_success "Directory exists: /etc/ssh/sshd_config.d/"
        
        print_step "2" "3" "Scanning for restrictive config files..."
        
        # Find all .conf files
        CONF_FILES=$(find /etc/ssh/sshd_config.d -name "*.conf" 2>/dev/null || true)
        
        if [ -n "$CONF_FILES" ]; then
            print_info "Found config files:"
            echo "$CONF_FILES" | while read -r conf_file; do
                echo "    - $(basename $conf_file)"
            done
            
            print_step "3" "3" "Fixing password authentication in all config files..."
            
            # Fix each config file
            echo "$CONF_FILES" | while read -r conf_file; do
                if [ -f "$conf_file" ]; then
                    # Check if file contains PasswordAuthentication no
                    if grep -q "PasswordAuthentication no" "$conf_file"; then
                        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' "$conf_file"
                        print_success "Fixed: $(basename $conf_file)"
                    fi
                fi
            done
        else
            print_info "No additional config files found"
        fi
    else
        print_info "Cloud-init config directory does not exist (not needed)"
    fi
}

set_user_password() {
    print_section "CONFIGURING USER PASSWORD"
    
    print_step "1" "1" "Setting password for user '$I2P_USER'..."
    
    # Generate a random password (user should change this)
    RANDOM_PASS=$(openssl rand -base64 12 | tr -d '/+=' | head -c 16)
    
    echo "${I2P_USER}:${RANDOM_PASS}" | chpasswd
    
    print_success "Password set for user '$I2P_USER'"
    print_warning "IMPORTANT: Random password generated (change after first login)"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  CREDENTIALS (SAVE THIS IMMEDIATELY)                                         ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  ${NC}Username: ${GREEN}${I2P_USER}${YELLOW}                                                              ║${NC}"
    echo -e "${YELLOW}║  ${NC}Password: ${GREEN}${RANDOM_PASS}${YELLOW}                                                   ║${NC}"
    echo -e "${YELLOW}║                                                                              ║${NC}"
    echo -e "${YELLOW}║  ${RED}⚠ CHANGE THIS PASSWORD IMMEDIATELY AFTER FIRST LOGIN${YELLOW}                       ║${NC}"
    echo -e "${YELLOW}║  ${CYAN}Command: passwd${YELLOW}                                                              ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Save to file
    echo "Username: ${I2P_USER}" > /root/aws_credentials.txt
    echo "Password: ${RANDOM_PASS}" >> /root/aws_credentials.txt
    echo "Generated: $(date)" >> /root/aws_credentials.txt
    chmod 600 /root/aws_credentials.txt
    
    print_info "Credentials also saved to: /root/aws_credentials.txt"
}

restart_ssh_service() {
    print_section "RESTARTING SSH SERVICE"
    
    print_step "1" "2" "Restarting SSH service..."
    systemctl restart "$SSH_SERVICE"
    print_success "SSH service restarted"
    
    print_step "2" "2" "Verifying SSH configuration..."
    
    # Test SSH config
    if sshd -t 2>/dev/null; then
        print_success "SSH configuration is valid"
    else
        print_error "SSH configuration has errors"
        sshd -t
        exit 1
    fi
    
    # Verify password auth is enabled
    PASSWORD_AUTH=$(sshd -T | grep "^passwordauthentication" | awk '{print $2}')
    
    if [ "$PASSWORD_AUTH" = "yes" ]; then
        print_success "Password authentication: ENABLED"
    else
        print_error "Password authentication: DISABLED (fix failed)"
        exit 1
    fi
}

##############################################################################
# I2P Network Configuration Functions
##############################################################################

diagnose_i2p_status() {
    print_section "DIAGNOSING I2P NETWORK STATUS"
    
    # Check if I2P is installed
    if [ ! -d "$I2P_CONFIG_DIR" ]; then
        print_warning "I2P is not installed or not configured"
        print_info "Skipping I2P network fixes"
        return 1
    fi
    
    print_step "1" "5" "Checking I2P service status..."
    
    if systemctl is-active --quiet i2p 2>/dev/null; then
        print_success "I2P service is running"
    else
        print_warning "I2P service is not running"
        print_info "Attempting to start I2P..."
        systemctl start i2p 2>/dev/null || true
        sleep 5
    fi
    
    print_step "2" "5" "Identifying I2P port configuration..."
    
    if [ -f "$ROUTER_CONFIG" ]; then
        I2P_PORT=$(grep "i2np.udp.port=" "$ROUTER_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")
        
        if [ -n "$I2P_PORT" ]; then
            print_success "I2P Port: $I2P_PORT"
        else
            print_warning "Could not determine I2P port (router may not be initialized)"
            I2P_PORT="21830"  # Default
            print_info "Using default port: $I2P_PORT"
        fi
    else
        print_warning "router.config not found"
        return 1
    fi
    
    print_step "3" "5" "Checking if I2P port is listening..."
    
    if netstat -tulnp 2>/dev/null | grep -q ":${I2P_PORT}"; then
        print_success "I2P is listening on port $I2P_PORT"
    else
        print_warning "I2P is not listening on port $I2P_PORT"
    fi
    
    print_step "4" "5" "Getting public IP address..."
    
    PUBLIC_IP=$(curl -s -m 5 ifconfig.me 2>/dev/null || curl -s -m 5 icanhazip.com 2>/dev/null || echo "Unknown")
    
    if [ "$PUBLIC_IP" != "Unknown" ]; then
        print_success "Public IP: $PUBLIC_IP"
    else
        print_warning "Could not determine public IP"
    fi
    
    print_step "5" "5" "Testing external port reachability..."
    
    if timeout 5 nc -zv "$PUBLIC_IP" "$I2P_PORT" >/dev/null 2>&1; then
        print_success "Port $I2P_PORT is externally reachable"
    else
        print_warning "Port $I2P_PORT may not be externally reachable"
        print_info "This will be fixed in the next section"
    fi
    
    return 0
}

fix_i2p_firewall() {
    print_section "FIXING I2P FIREWALL CONFIGURATION"
    
    if [ -z "$I2P_PORT" ]; then
        print_warning "I2P port not identified, skipping firewall fixes"
        return
    fi
    
    print_step "1" "5" "Checking UFW firewall status..."
    
    if command -v ufw >/dev/null 2>&1; then
        UFW_STATUS=$(ufw status | head -1 | awk '{print $2}')
        
        if [ "$UFW_STATUS" = "active" ]; then
            print_success "UFW is active"
            
            print_step "2" "5" "Opening I2P ports in UFW..."
            
            # Open I2P port range (main port ± 100 for flexibility)
            PORT_START=$((I2P_PORT - 100))
            PORT_END=$((I2P_PORT + 100))
            
            ufw allow ${PORT_START}:${PORT_END}/tcp comment "I2P TCP range" >/dev/null 2>&1
            ufw allow ${PORT_START}:${PORT_END}/udp comment "I2P UDP range" >/dev/null 2>&1
            
            # Open specific I2P port
            ufw allow ${I2P_PORT}/tcp comment "I2P primary TCP" >/dev/null 2>&1
            ufw allow ${I2P_PORT}/udp comment "I2P primary UDP" >/dev/null 2>&1
            
            # Open I2P console (local only)
            ufw allow from 127.0.0.1 to any port 7657 proto tcp comment "I2P console" >/dev/null 2>&1
            
            ufw reload >/dev/null 2>&1
            
            print_success "UFW rules updated"
            print_info "Opened ports: ${PORT_START}-${PORT_END} (TCP+UDP)"
        else
            print_info "UFW is not active"
        fi
    else
        print_info "UFW not installed (may be using AWS security groups only)"
    fi
    
    print_step "3" "5" "Checking for interface binding issues..."
    
    # Check if I2P is bound to localhost only
    if [ -f "$ROUTER_CONFIG" ]; then
        BIND_HOST=$(grep "^i2np.udp.host=" "$ROUTER_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")
        
        if [ "$BIND_HOST" = "127.0.0.1" ] || [ "$BIND_HOST" = "localhost" ]; then
            print_warning "I2P is bound to localhost only"
            print_info "Removing localhost binding..."
            
            sed -i '/^i2np.udp.host=/d' "$ROUTER_CONFIG"
            sed -i '/^i2np.ntcp2.hostname=/d' "$ROUTER_CONFIG"
            
            print_success "Interface binding fixed (will bind to all interfaces)"
            
            print_step "4" "5" "Restarting I2P to apply changes..."
            systemctl restart i2p
            sleep 10
            print_success "I2P restarted"
        else
            print_success "I2P is correctly configured to bind to all interfaces"
        fi
    fi
    
    print_step "5" "5" "Verifying I2P network status..."
    
    sleep 5  # Give I2P time to start
    
    # Try to get network status from console
    NETWORK_STATUS=$(curl -s http://127.0.0.1:7657/summarynoframe.jsp 2>/dev/null | grep -oP 'Network: \K[A-Za-z]+' || echo "Unknown")
    
    if [ "$NETWORK_STATUS" = "OK" ]; then
        print_success "I2P Network Status: OK"
    elif [ "$NETWORK_STATUS" = "Testing" ]; then
        print_warning "I2P Network Status: Testing (wait 5-10 minutes)"
    else
        print_info "I2P Network Status: $NETWORK_STATUS (may need time to integrate)"
    fi
}

fix_aws_security_group_reminder() {
    print_section "AWS SECURITY GROUP CONFIGURATION REMINDER"
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  IMPORTANT: AWS SECURITY GROUP CONFIGURATION                                 ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  ${NC}This script fixes internal firewall settings, but you MUST also configure   ${YELLOW}║${NC}"
    echo -e "${YELLOW}║  ${NC}AWS Security Groups in the AWS Console.                                     ${YELLOW}║${NC}"
    echo -e "${YELLOW}║                                                                              ║${NC}"
    echo -e "${YELLOW}║  ${CYAN}Required Inbound Rules:${YELLOW}                                                      ║${NC}"
    echo -e "${YELLOW}║  ${GREEN}• SSH (22/tcp)${YELLOW}         - Your IP or 0.0.0.0/0 for worldwide access        ║${NC}"
    
    if [ -n "$I2P_PORT" ]; then
        echo -e "${YELLOW}║  ${GREEN}• I2P (${I2P_PORT}/tcp)${YELLOW}   - 0.0.0.0/0 (all sources)                          ║${NC}"
        echo -e "${YELLOW}║  ${GREEN}• I2P (${I2P_PORT}/udp)${YELLOW}   - 0.0.0.0/0 (all sources)                          ║${NC}"
    else
        echo -e "${YELLOW}║  ${GREEN}• I2P (check port)${YELLOW}    - 0.0.0.0/0 (all sources, TCP+UDP)                 ║${NC}"
    fi
    
    echo -e "${YELLOW}║                                                                              ║${NC}"
    echo -e "${YELLOW}║  ${CYAN}How to Configure:${YELLOW}                                                            ║${NC}"
    echo -e "${YELLOW}║  ${NC}1. AWS Console → EC2 → Security Groups                                     ${YELLOW}║${NC}"
    echo -e "${YELLOW}║  ${NC}2. Select your instance's security group                                   ${YELLOW}║${NC}"
    echo -e "${YELLOW}║  ${NC}3. Edit Inbound Rules → Add the rules above                                ${YELLOW}║${NC}"
    echo -e "${YELLOW}║  ${NC}4. Save changes                                                            ${YELLOW}║${NC}"
    echo -e "${YELLOW}║                                                                              ║${NC}"
    echo -e "${YELLOW}║  ${RED}⚠ Without these AWS-level rules, I2P will remain firewalled${YELLOW}                ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

##############################################################################
# Verification & Summary
##############################################################################

display_final_summary() {
    print_section "CONFIGURATION COMPLETE - SUMMARY"
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  SSH CONFIGURATION                                                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} Password authentication: ${GREEN}ENABLED${NC}"
    echo -e "  ${GREEN}✓${NC} User: ${CYAN}${I2P_USER}${NC}"
    
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "Unknown" ]; then
        echo -e "  ${GREEN}✓${NC} SSH access: ${CYAN}ssh ${I2P_USER}@${PUBLIC_IP}${NC}"
    fi
    
    echo ""
    
    if [ -f "$ROUTER_CONFIG" ] && [ -n "$I2P_PORT" ]; then
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║  I2P CONFIGURATION                                                           ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}✓${NC} I2P Port: ${CYAN}${I2P_PORT}${NC}"
        echo -e "  ${GREEN}✓${NC} Firewall: ${GREEN}Configured${NC}"
        
        if [ "$NETWORK_STATUS" = "OK" ]; then
            echo -e "  ${GREEN}✓${NC} Network Status: ${GREEN}OK${NC}"
        elif [ "$NETWORK_STATUS" = "Testing" ]; then
            echo -e "  ${YELLOW}⏳${NC} Network Status: ${YELLOW}Testing (wait 5-10 min)${NC}"
        else
            echo -e "  ${YELLOW}⚠${NC} Network Status: ${YELLOW}${NETWORK_STATUS}${NC}"
        fi
        
        if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "Unknown" ]; then
            echo -e "  ${CYAN}→${NC} Console URL: ${CYAN}http://127.0.0.1:7657${NC} (via SSH tunnel or RDP)"
        fi
        
        echo ""
    fi
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  BACKUPS                                                                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} Configuration backups: ${CYAN}${BACKUP_DIR}${NC}"
    echo -e "  ${GREEN}✓${NC} Credentials saved: ${CYAN}/root/aws_credentials.txt${NC}"
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  NEXT STEPS                                                                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}1.${NC} ${CYAN}Test SSH login from your local machine:${NC}"
    
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "Unknown" ]; then
        echo -e "     ${GREEN}ssh ${I2P_USER}@${PUBLIC_IP}${NC}"
    else
        echo -e "     ${GREEN}ssh ${I2P_USER}@<YOUR_PUBLIC_IP>${NC}"
    fi
    
    echo ""
    echo -e "  ${YELLOW}2.${NC} ${CYAN}Change the default password immediately:${NC}"
    echo -e "     ${GREEN}passwd${NC}"
    echo ""
    echo -e "  ${YELLOW}3.${NC} ${CYAN}Configure AWS Security Group (see reminder above)${NC}"
    echo ""
    
    if [ -f "$ROUTER_CONFIG" ]; then
        echo -e "  ${YELLOW}4.${NC} ${CYAN}Wait 10-15 minutes for I2P network integration${NC}"
        echo ""
        echo -e "  ${YELLOW}5.${NC} ${CYAN}Verify I2P status:${NC}"
        echo -e "     ${GREEN}curl -s http://127.0.0.1:7657/summarynoframe.jsp | grep 'Network:'${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  TROUBLESHOOTING                                                             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}If SSH still doesn't work:${NC}"
    echo -e "    • Verify AWS Security Group allows port 22 from your IP"
    echo -e "    • Check AWS Network ACLs"
    echo -e "    • Verify instance has public IP assigned"
    echo ""
    echo -e "  ${CYAN}If I2P shows 'Firewalled':${NC}"
    echo -e "    • Configure AWS Security Group (see reminder above)"
    
    if [ -n "$I2P_PORT" ]; then
        echo -e "    • Verify ports ${I2P_PORT}/tcp and ${I2P_PORT}/udp are open"
    fi
    
    echo -e "    • Wait 15-30 minutes for network integration"
    echo -e "    • Check logs: ${GREEN}tail -f /home/${I2P_USER}/.i2p/wrapper.log${NC}"
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  SUPPORT                                                                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}Documentation:${NC} Run script with ${GREEN}--help${NC} flag"
    echo -e "  ${CYAN}Restore backups:${NC} Files saved in ${GREEN}${BACKUP_DIR}${NC}"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ AWS EC2 Configuration Fix Complete${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Design by: Siddique Abubakar Muntaka${NC}"
    echo -e "${CYAN}Center of Anonymity Networks - University of Cincinnati${NC}"
    echo -e "${CYAN}Advisor: Dr. Jacques Bou Abdo${NC}"
    echo ""
}

##############################################################################
# Main Execution
##############################################################################

main() {
    print_header
    
    # Verify running as root
    verify_root
    
    # Verify I2P user exists
    verify_i2p_user_exists
    
    # Create backups
    create_backups
    
    # Fix SSH
    detect_ssh_service
    fix_main_ssh_config
    fix_cloud_init_ssh_override
    set_user_password
    restart_ssh_service
    
    # Fix I2P (if installed)
    if diagnose_i2p_status; then
        fix_i2p_firewall
        fix_aws_security_group_reminder
    fi
    
    # Display summary
    display_final_summary
}

# Execute main function
main

exit 0
