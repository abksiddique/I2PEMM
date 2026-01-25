# AWS EC2 SSH & I2P Configuration Fix Script - Usage Guide

**Design by:** Siddique Abubakar Muntaka  
**University of Cincinnati** - PhD Information Technology  
**Advisor:** Dr. Jacques Bou Abdo  
**Center of Anonymity Networks**

---

## 📋 Overview

This script automatically fixes two critical issues with AWS EC2 Ubuntu instances:

1. **SSH Password Authentication** - AWS disables password-based SSH by default
2. **I2P Network Firewall** - I2P routers show "Firewalled" status due to misconfigurations

### Problems Solved

| Problem | Symptom | Solution |
|---------|---------|----------|
| **SSH Key-Only Auth** | PuTTY error: "No supported authentication methods" | Enables password authentication |
| **Cloud-Init Override** | Password auth settings ignored | Fixes `/etc/ssh/sshd_config.d/` files |
| **I2P Firewalled** | Network status shows "Firewalled with UDP Disabled" | Opens firewall ports, fixes binding |
| **Port Not Reachable** | Cannot connect to I2P from outside | Configures UFW + AWS security groups |

---

## 🚀 Quick Start

### Method 1: AWS EC2 Instance Connect (Recommended)

**Best for:** Brand new instances where you can't SSH yet

1. **AWS Console** → EC2 → Instances
2. Select your instance → Click **"Connect"**
3. Choose **"EC2 Instance Connect"**
4. Browser terminal opens → Run these commands:

```bash
# Download the script
wget https://YOUR-GITHUB-URL/AWS_EC2_Fix_Script.sh

# Make it executable
chmod +x AWS_EC2_Fix_Script.sh

# Run as root
sudo ./AWS_EC2_Fix_Script.sh
```

**OR** if you have the script locally:

```bash
# Paste the entire script content
cat > AWS_EC2_Fix_Script.sh << 'EOF'
#!/bin/bash
[... paste entire script ...]
EOF

# Make executable and run
chmod +x AWS_EC2_Fix_Script.sh
sudo ./AWS_EC2_Fix_Script.sh
```

---

### Method 2: AWS Systems Manager (No SSH Required)

**Best for:** Instances where EC2 Instance Connect doesn't work

1. **AWS Console** → Systems Manager → Session Manager
2. Click **"Start session"**
3. Select your instance
4. Browser terminal opens → Follow same steps as Method 1

---

### Method 3: Using Existing SSH Key (If You Have It)

**Best for:** You have the original `.pem` key file

```bash
# On your local machine (Linux/Mac)
scp -i your-key.pem AWS_EC2_Fix_Script.sh ubuntu@YOUR_AWS_IP:/tmp/

# SSH into instance
ssh -i your-key.pem ubuntu@YOUR_AWS_IP

# Run the script
sudo /tmp/AWS_EC2_Fix_Script.sh
```

**On Windows with PuTTY:**
1. Convert `.pem` to `.ppk` using PuTTYgen
2. Use PSCP to upload script
3. Connect with PuTTY and run script

---

## 📊 What the Script Does

### Phase 1: SSH Configuration Fix

```
✓ Detects SSH service name (ssh.service vs sshd.service)
✓ Enables PasswordAuthentication in main config
✓ Fixes cloud-init override files (60-cloudimg-settings.conf)
✓ Enables ChallengeResponseAuthentication
✓ Enables KbdInteractiveAuthentication
✓ Generates random password for 'sid' user
✓ Restarts SSH service
✓ Verifies configuration
```

### Phase 2: I2P Network Configuration Fix (If I2P Installed)

```
✓ Detects I2P port from router.config
✓ Opens firewall ports (UFW)
✓ Fixes interface binding issues (removes 127.0.0.1 binding)
✓ Restarts I2P service
✓ Verifies network status
✓ Provides AWS Security Group configuration reminder
```

### Phase 3: Backup & Documentation

```
✓ Backs up all modified configs
✓ Saves credentials to /root/aws_credentials.txt
✓ Displays comprehensive summary
✓ Provides troubleshooting steps
```

---

## 🔐 Security Features

### Automatic Backup

All configurations are backed up before modification:

```
/root/aws-fix-backups-YYYYMMDD_HHMMSS/
├── sshd_config.backup
├── 60-cloudimg-settings.conf.backup
└── router.config.backup (if I2P installed)
```

### Credential Management

- Generates secure random password
- Saves credentials to `/root/aws_credentials.txt` (root-only access)
- Displays credentials on screen ONCE during execution
- Prompts user to change password immediately

### Restoration

To restore previous configuration:

```bash
# Find your backup
ls -la /root/aws-fix-backups-*/

# Restore SSH config
sudo cp /root/aws-fix-backups-TIMESTAMP/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart ssh

# Restore I2P config (if needed)
sudo cp /root/aws-fix-backups-TIMESTAMP/router.config.backup /home/sid/.i2p/router.config
sudo systemctl restart i2p
```

---

## 📝 Script Output Example

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  AWS EC2 SSH & I2P Network Configuration Fix                                ║
║                                                                              ║
║  Automatically resolves SSH authentication and I2P firewall issues          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

Design by: Siddique Abubakar Muntaka
Center of Anonymity Networks - University of Cincinnati
Advisor: Dr. Jacques Bou Abdo

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CREATING CONFIGURATION BACKUPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Step 1/2] Creating backup directory...
  ✓ Backup directory: /root/aws-fix-backups-20251122_160530
[Step 2/2] Backing up SSH configurations...
  ✓ Backed up: sshd_config
  ✓ Backed up: 60-cloudimg-settings.conf
  ✓ Backed up: router.config

[... continues with all fixes ...]

╔══════════════════════════════════════════════════════════════════════════════╗
║  CREDENTIALS (SAVE THIS IMMEDIATELY)                                         ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Username: sid                                                               ║
║  Password: aB3xK9mP5nQ8zR2w                                                  ║
║                                                                              ║
║  ⚠ CHANGE THIS PASSWORD IMMEDIATELY AFTER FIRST LOGIN                       ║
║  Command: passwd                                                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## ✅ Post-Script Checklist

### 1. Test SSH Connection

```bash
# From your local machine
ssh sid@YOUR_AWS_PUBLIC_IP

# Enter the password displayed during script execution
```

**Expected:** Successful login

---

### 2. Change Default Password

```bash
# Immediately after first login
passwd

# Enter old password (from script output)
# Enter new password twice
```

---

### 3. Configure AWS Security Group

The script fixes **internal** firewall settings, but you must also configure **AWS-level** security groups:

#### Required Inbound Rules:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP or 0.0.0.0/0 | SSH access |
| Custom TCP | TCP | I2P Port (e.g., 21830) | 0.0.0.0/0 | I2P TCP traffic |
| Custom UDP | UDP | I2P Port (e.g., 21830) | 0.0.0.0/0 | I2P UDP traffic |

**How to Configure:**

1. AWS Console → EC2 → Security Groups
2. Select your instance's security group
3. **Inbound rules** tab → **Edit inbound rules**
4. **Add rule** for each row above
5. **Save rules**

**Finding your I2P port:**
```bash
grep "i2np.udp.port=" /home/sid/.i2p/router.config
```

---

### 4. Verify I2P Network Status

Wait 10-15 minutes after script completion, then check:

```bash
# Check network status
curl -s http://127.0.0.1:7657/summarynoframe.jsp | grep "Network:"

# Check peer count
curl -s http://127.0.0.1:7657/summarynoframe.jsp | grep "Peers"

# Check if port is externally reachable
nc -zv $(curl -s ifconfig.me) $(grep "i2np.udp.port=" /home/sid/.i2p/router.config | cut -d'=' -f2)
```

**Expected Results:**
- Network: OK (or "Testing" if still integrating)
- Peers: 10+ active
- Port test: Connection succeeded

---

## 🔧 Troubleshooting

### Problem: SSH Still Doesn't Work

**Symptoms:**
```
Permission denied (publickey)
```

**Solutions:**

1. **Verify AWS Security Group:**
   - Check port 22 is open from your IP
   - Source should be `Your IP/32` or `0.0.0.0/0`

2. **Check SSH Service:**
   ```bash
   sudo systemctl status ssh
   sudo sshd -T | grep passwordauthentication
   ```
   Should show `passwordauthentication yes`

3. **Check User Exists:**
   ```bash
   id sid
   ```

4. **Try Different SSH Client:**
   - Windows: Try both PuTTY and Windows `ssh` command
   - Verify you're using password auth, not key auth

---

### Problem: I2P Still Shows "Firewalled"

**Symptoms:**
```
Network: Firewalled with UDP Disabled
```

**Solutions:**

1. **Verify AWS Security Group (Most Common Issue):**
   - Must allow TCP **AND** UDP for your I2P port
   - Source must be `0.0.0.0/0` (not just your IP)

2. **Check UFW:**
   ```bash
   sudo ufw status | grep $(grep "i2np.udp.port=" /home/sid/.i2p/router.config | cut -d'=' -f2)
   ```

3. **Test External Reachability:**
   ```bash
   PUBLIC_IP=$(curl -s ifconfig.me)
   I2P_PORT=$(grep "i2np.udp.port=" /home/sid/.i2p/router.config | cut -d'=' -f2)
   nc -zv $PUBLIC_IP $I2P_PORT
   ```

4. **Wait Longer:**
   - I2P can take 15-30 minutes to fully integrate
   - Check status periodically

5. **Check I2P Logs:**
   ```bash
   tail -100 /home/sid/.i2p/wrapper.log | grep -i "firewall\|reachable\|testing"
   ```

---

### Problem: Script Fails During Execution

**Symptoms:**
```
Error: [specific error message]
```

**Solutions:**

1. **Check if Running as Root:**
   ```bash
   sudo ./AWS_EC2_Fix_Script.sh
   ```

2. **Check Disk Space:**
   ```bash
   df -h
   ```

3. **Check System Updates:**
   ```bash
   sudo apt update
   sudo apt upgrade
   ```

4. **View Full Error:**
   - Script shows detailed error messages
   - Check `/var/log/syslog` for system-level errors

5. **Restore Backup:**
   ```bash
   ls /root/aws-fix-backups-*/
   # Restore from latest backup
   ```

---

## 📚 Advanced Usage

### Running on Multiple Instances

**Option A: AWS Systems Manager - Run Command**

1. AWS Console → Systems Manager → Run Command
2. Command document: `AWS-RunShellScript`
3. Paste entire script content
4. Select multiple instances
5. Execute

**Option B: Ansible Playbook** (for large deployments)

```yaml
---
- hosts: aws_instances
  become: yes
  tasks:
    - name: Upload fix script
      copy:
        src: AWS_EC2_Fix_Script.sh
        dest: /tmp/fix_script.sh
        mode: '0755'
    
    - name: Execute fix script
      shell: /tmp/fix_script.sh
      register: output
    
    - name: Display results
      debug:
        var: output.stdout_lines
```

---

### Automated Deployment (User Data)

**For fresh EC2 instances**, include script in User Data:

```bash
#!/bin/bash
# Download and run fix script on first boot
wget -O /tmp/aws_fix.sh https://YOUR-URL/AWS_EC2_Fix_Script.sh
chmod +x /tmp/aws_fix.sh
/tmp/aws_fix.sh

# Optional: Install I2P research stack
wget -O /tmp/01_system_preparation.sh https://YOUR-URL/01_system_preparation.sh
# ... continue with other scripts
```

---

## 📖 Technical Details

### Files Modified

| File | Purpose | Changes |
|------|---------|---------|
| `/etc/ssh/sshd_config` | Main SSH config | Enables password authentication |
| `/etc/ssh/sshd_config.d/60-cloudimg-settings.conf` | Cloud-init override | Changes `PasswordAuthentication no` → `yes` |
| `/home/sid/.i2p/router.config` | I2P configuration | Removes localhost binding if present |

### Firewall Rules Added

```bash
# UFW Rules
ufw allow [PORT-100]:[PORT+100]/tcp  # I2P TCP range
ufw allow [PORT-100]:[PORT+100]/udp  # I2P UDP range
ufw allow [PORT]/tcp                  # I2P primary TCP
ufw allow [PORT]/udp                  # I2P primary UDP
```

### System Changes

- No kernel parameters modified
- No system packages installed/removed
- Only configuration files changed
- All changes are reversible via backups

---

## 🎓 Integration with Research Infrastructure

This script is part of the complete I2P research infrastructure deployment:

**Deployment Order:**
1. ✅ Launch AWS EC2 instance
2. ✅ **Run AWS_EC2_Fix_Script.sh** (this script)
3. ✅ Run Scripts 1-5 (system setup + I2P installation)
4. ✅ Run Script 6 (floodfill) or Script 9 (standard router)
5. ✅ Optional: Run Script 7 (desktop/RDP)
6. ✅ Optional: Run Script 10 or 11 (maximum immersion)

---

## 📞 Support

### Script Logs

All script output is displayed on screen. To save for later:

```bash
sudo ./AWS_EC2_Fix_Script.sh | tee /tmp/fix_script_output.log
```

### Backup Location

```bash
ls -la /root/aws-fix-backups-*/
cat /root/aws_credentials.txt
```

### Verification Commands

```bash
# SSH Configuration
sudo sshd -T | grep passwordauthentication

# I2P Status
systemctl status i2p
curl -s http://127.0.0.1:7657/summarynoframe.jsp | grep "Network:"

# Firewall Rules
sudo ufw status verbose
```

---

## ⚠️ Important Notes

1. **Credential Security:**
   - Change the generated password IMMEDIATELY after first login
   - Delete `/root/aws_credentials.txt` after saving password elsewhere

2. **AWS Security Groups:**
   - Script cannot modify AWS Security Groups (AWS API limitation)
   - You MUST configure security groups manually in AWS Console

3. **Time Requirements:**
   - Script execution: 30-60 seconds
   - I2P network integration: 15-30 minutes after script completion

4. **Compatibility:**
   - Tested on Ubuntu 24.04 LTS (AWS AMI)
   - Should work on Ubuntu 22.04, 20.04
   - May need modifications for other distributions

---

## 📋 Summary

**What This Script Does:**
- ✅ Enables SSH password authentication
- ✅ Fixes cloud-init SSH overrides
- ✅ Configures I2P firewall rules
- ✅ Sets up user account with secure password
- ✅ Creates comprehensive backups
- ✅ Provides detailed troubleshooting info

**What You Must Do:**
- ⚠️ Configure AWS Security Groups (cannot be automated)
- ⚠️ Change default password after first login
- ⚠️ Wait 15-30 minutes for I2P network integration

**Expected Results:**
- ✅ SSH access working with password
- ✅ I2P network status: OK (after integration period)
- ✅ All configurations backed up and documented

---

**Design by:** Siddique Abubakar Muntaka  
**University of Cincinnati** - Center of Anonymity Networks  
**Advisor:** Dr. Jacques Bou Abdo  
**Version:** 1.0  
**Date:** November 22, 2025
