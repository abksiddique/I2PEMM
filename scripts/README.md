# I2P Research Infrastructure Deployment Scripts

**Design by:** Siddique Abubakar Muntaka  
**University of Cincinnati** - PhD Information Technology  
**Advisor:** Dr. Jacques Bou Abdo  
**Lab:** Center of Anonymity Networks  
**School of Information Technology**

---

## Overview

Automated deployment scripts for setting up I2P (Invisible Internet Project) research infrastructure on Ubuntu 24.04 VPS instances. These scripts deploy a complete I2P garlic routing node with GUI access, firewall protection, and floodfill/standard router capability for network topology research paper titled (The Emerging Network Topology of the Invisible Internet Project: Mathematical Modeling and Empirical Validation).

## System Requirements

- **OS:** Ubuntu 24.04 LTS (clean installation)
- **RAM:** 2GB/4GB minimum
- **Storage:** 60GB minimum
- **Network:** 1Gbps recommended
- **Access:** Root SSH access

## Script Structure

The deployment is divided into 6 sequential scripts:

### Script 1: System & User Setup
**File:** `01_system_user_setup.sh`  
**Purpose:** Update system packages and create research user  
**Runtime:** ~2-5 minutes  
**Reboot Required:** No

### Script 2: Desktop & RDP Setup
**File:** `02_desktop_rdp_setup.sh`  
**Purpose:** Install XFCE desktop, Firefox, and xrdp for remote access  
**Runtime:** ~5-10 minutes  
**Reboot Required:** No

### Script 3: Firewall Configuration
**File:** `03_firewall_setup.sh`  
**Purpose:** Configure UFW with SSH, RDP, and I2P ports  
**Runtime:** ~1 minute  
**Reboot Required:** No

### Script 4: Java & I2P Installation
**File:** `04_java_i2p_install.sh`  
**Purpose:** Install Java, download I2P v2.10.0, verify checksum, install  
**Runtime:** ~3-5 minutes  
**Reboot Required:** No

### Script 5: I2P System Configuration
**File:** `05_i2p_configuration.sh`  
**Purpose:** Fix I2P paths, create systemd service, enable auto-start  
**Runtime:** ~1 minute  
**Reboot Required:** No

### Script 6: Research Configuration
**File:** `06_i2p_research_config.sh`  
**Purpose:** Apply bandwidth settings, enable floodfill, finalize setup  
**Runtime:** ~1 minute  
**Reboot Required:** No

---

## Quick Start

### Step 1: Upload Scripts to VPS

```bash
# Create deployment directory
mkdir -p /root/i2p-deployment
cd /root/i2p-deployment

# Upload all 6 scripts to this directory
# Make scripts executable
chmod +x *.sh
```

### Step 2: Configure User Password

Edit `01_system_user_setup.sh` and change the password:

```bash
nano 01_system_user_setup.sh
# Change line: USER_PASSWORD="I2Presearch2025!"
```

### Step 3: Run Scripts Sequentially

```bash
# Script 1: System & User
./01_system_user_setup.sh

# Script 2: Desktop & RDP
./02_desktop_rdp_setup.sh

# Script 3: Firewall
./03_firewall_setup.sh

# Script 4: Java & I2P Install
./04_java_i2p_install.sh

# Script 5: I2P Configuration
./05_i2p_configuration.sh

# Script 6: Research Config
./06_i2p_research_config.sh
```

### Step 4: Access I2P Console

1. Connect via Windows Remote Desktop to your VPS IP (port 3389)
2. Login with username `sid` and your configured password
3. Open Firefox browser
4. Navigate to: `http://127.0.0.1:7657`

---

## Configuration Details

### Default User
- **Username:** `sid`
- **Password:** Set in Script 1 (default: `I2Presearch2025!`)
- **Privileges:** sudo access

### Firewall Ports
- **22/tcp** - SSH management
- **3389/tcp** - Remote Desktop (RDP)
- **24180/udp** - I2P SSU2 protocol
- **24180/tcp** - I2P NTCP2 protocol

### I2P Configuration
- **Installation:** `/home/sid/i2p`
- **Config Directory:** `/home/sid/.i2p`
- **Console URL:** `http://127.0.0.1:7657`
- **Bandwidth:** ~73 MB/s (configured for 1Gbps VPS)
- **Floodfill:** Enabled (activates after 2+ hours uptime)
- **Share Ratio:** 80% (participating traffic)

### Service Management
```bash
# Check I2P status
systemctl status i2p.service

# Stop I2P
systemctl stop i2p.service

# Start I2P
systemctl start i2p.service

# Restart I2P
systemctl restart i2p.service

# View logs
journalctl -u i2p.service -f
```

---

## Research Notes

### Network Integration Timeline
- **0-30 minutes:** Initial bootstrap, peer discovery
- **30-120 minutes:** Network integration, tunnel building
- **2+ hours:** Floodfill eligibility (if enabled)
- **Status indicators:** Check console at http://127.0.0.1:7657

### Participating Tunnels
The router will show "Rejecting tunnels: Starting up" initially. This is normal. After 30-120 minutes of uptime, it will begin accepting participating tunnels from other I2P nodes.

### Floodfill Status
With `router.floodfillParticipant=true` configured, the router will become a floodfill node after:
- 2+ hours continuous uptime
- Stable network connectivity
- Good bandwidth availability

### Data Collection
For research purposes, relevant logs and statistics are available:
- Router console: http://127.0.0.1:7657
- Router logs: `/home/sid/.i2p/wrapper.log`
- System journal: `journalctl -u i2p.service`

---

## Troubleshooting

### Script Fails
Each script has error handling with `set -e`. If a script fails:
1. Check error message
2. Fix the issue
3. Re-run the failed script
4. Continue with subsequent scripts

### I2P Won't Start
```bash
# Check service status
systemctl status i2p.service

# Check logs
journalctl -u i2p.service -n 50

# Verify paths
ls -la /home/sid/.i2p/
```

### RDP Connection Fails
```bash
# Verify xrdp is running
systemctl status xrdp

# Check firewall
ufw status

# Verify .xsession file
cat /home/sid/.xsession
```

### Firewall Issues
```bash
# View current rules
ufw status verbose

# Check if ports are listening
netstat -tlnp | grep -E "22|3389|24180"
```

---

## Security Considerations

1. **Change default password** in Script 1 before deployment
2. **SSH key authentication** recommended over password
3. **Regular updates:** Run `apt update && apt upgrade` periodically
4. **Firewall:** UFW is configured with minimal required ports
5. **Monitoring:** Review I2P logs regularly for anomalies

---

## Academic Use

These scripts are designed for legitimate I2P network research including:
- Network topology analysis
- Peer selection mechanisms
- Tunnel formation patterns
- Floodfill router behavior
- Garlic routing performance

**Ethics:** All research should comply with institutional review board (IRB) requirements and I2P network policies.

---

## Citation

If you use these scripts in your research, please cite:

```
Muntaka, S. A. (2025). I2P Research Infrastructure Deployment Scripts.
Center of Anonymity Networks, School of Information Technology,
University of Cincinnati. Advisor: Dr. Jacques Bou Abdo.
```

---

## License

These scripts are provided for academic and research purposes.

---

## Support

**Primary Contact:** Siddique Abubakar Muntaka  
**Institution:** University of Cincinnati  
**Lab:** Center of Anonymity Networks  
**Advisor:** Dr. Jacques Bou Abdo

---

**Version:** 1.0  
**Last Updated:** November 2025  
