# 🌐 XLX Debian Installer

<div align="center">

![XLX Version](https://img.shields.io/badge/XLX-v2.5.3-blue)
![Debian](https://img.shields.io/badge/Debian-10%2B-red)
![License](https://img.shields.io/badge/license-MIT-green)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)

**Automated installation script for XLX multi-mode reflectors**

Supporting D-Star • C4FM • DMR protocols

[Features](#-features) • [Quick Start](#-quick-start) • [Installation](#-installation) • [Configuration](#%EF%B8%8F-firewall-configuration)

</div>

---

## 📖 About

This project simplifies the installation of XLX reflectors with minimal user intervention. Developed by **Daniel K. ([PU5KOD](https://www.qrz.com/db/PU5KOD))**, this installer automates the setup of the XLX reflector created by [LX3JL](https://github.com/LX3JL/xlxd) and includes a customized dark theme dashboard.

**Upon completion, you'll have a fully functional public D-Star/YSF/DMR XLX reflector with monitoring dashboard!** 🎉

### 🎯 Key Highlights

- ✅ **No AMBE hardware needed** for C4FM and DMR interoperability (since early 2020)
- ✅ **Dark theme dashboard** with improvements and modern UI
- ✅ **Lightweight** - runs on Raspberry Pi Zero
- ✅ **Optional Echo Test** (Parrot) service on Module E
- ✅ **Compatible** with Debian 10+ (13 recommended), Ubuntu, RaspiOS, and Armbian

> **Note:** D-Star integration with other modes still requires AMBE chips. For D-Star-only or YSF/DMR reflectors, no additional hardware is needed.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 **Multi-Protocol** | Native support for D-Star, C4FM (YSF), and DMR |
| 🎨 **Custom Dashboard** | Dark theme with enhanced monitoring capabilities |
| 🔊 **Echo Test** | Optional Parrot service for audio testing (Module E) |
| 🔒 **SSL Ready** | Automated SSL certificate setup with Certbot |
| 📊 **Real-time Monitoring** | Live connection tracking and statistics |
| 🌍 **YSF Auto-link** | Configurable automatic linking for YSF |

---

## 📋 Requirements

Before installation, ensure you have:

- [x] Debian-based system or VPS with latest updates
- [x] Stable internet connection with **fixed public IP**
- [x] Firewall management capabilities
- [x] **FQDN** for dashboard (e.g., `xlxbra.net`)
- [x] Unique **3-digit XLX suffix** (check availability [here](https://xlxbra.net/index.php?show=reflectors))

### 🔍 Finding Available Reflector Suffixes

Visit the [active reflector dashboard](https://xlxbra.net/index.php?show=reflectors) to see which XLX suffixes are in use. Any unlisted suffix is available!

---

## 🚀 Quick Start

```bash
# Update system
sudo apt update && sudo apt full-upgrade -y

# Install prerequisites
sudo apt install git -y

# Clone repository
cd /usr/src/
sudo git clone https://github.com/PU5KOD/XLX_Installer.git

# Run installer
cd XLX_Installer/ && sudo chmod +x *.sh
sudo ./installer.sh
# or
sudo ./Installer_v2.sh
```

---

## 📦 Installation

### Step 1: Configure Firewall Ports

**Before running the installer**, ensure all required ports are open and forwarded (see [Firewall Configuration](#%EF%B8%8F-firewall-configuration)).

### Step 2: Run Installation

Execute the commands from the [Quick Start](#-quick-start) section above.

### Step 3: Configuration Prompts

The installer will request the following information:

| Prompt | Example | Default |
|--------|---------|---------|
| 3-digit XLX reflector | `300`, `US1`, `BRA` | - |
| Dashboard FQDN | `xlx.domain.com` | - |
| Sysop email address | `you@example.com` | - |
| Sysop callsign | `PU5KOD` | - |
| Reflector country | `Brazil` | - |
| Time Zone | `America/Sao_Paulo` | - |
| Comment for XLX list | `My XLX Reflector` | - |
| Custom tab name | `XLX Dashboard` | - |
| Custom footnote | `Maintained by...` | - |
| Install SSL? | `Y/N` | N |
| Install Echo Test? | `Y/N` | N |
| Number of modules | `1-26` | 26 |
| YSF UDP port | `1-65535` | 42000 |
| YSF Wires-X frequency | `433125000` (Hz) | - |
| Enable YSF auto-link? | `Y/N` | N |
| YSF auto-link module | `A-Z` | - |

### Step 4: Completion ✅

The installation proceeds automatically. Once complete, your reflector will be operational and ready to accept connections!

---

## 🛡️ Firewall Configuration

### Required Ports

#### TCP Ports
```
22     SSH
80     HTTP
443    HTTPS
8080   RepNet (optional)
20001-20005   DPlus protocol
40001  ICom G3
```

#### UDP Ports
```
8880   DMR+ DMO mode
10001  JSON interface XLX Core
10002  XLX interlink
10100  AMBE controller
10101-10199   AMBE transcoding
12345-12346   ICom Terminal presence/request
20001-20005   DPlus protocol
21110  Yaesu IMRS protocol
30001  DExtra protocol
30051  DCS protocol
40000  Terminal DV
42000  YSF protocol
62030  MMDVM protocol
```

---

## 📂 File Locations

| Type | Location |
|------|----------|
| **Installation** | `/xlxd/` |
| **Source Folders** | `/usr/src/xlxd/`<br>`/usr/src/XLXEcho/`<br>`/usr/src/XLX_Dark_Dashboard/`<br>`/usr/src/XLX_Installer/` |
| **Log Files** | `/var/log/xlxd*`<br>`/var/log/xlx.log`<br>`/var/log/xlxecho.log` |
| **Services** | `/etc/systemd/system/xlxd.service`<br>`/etc/systemd/system/xlxecho.service`<br>`/etc/systemd/system/xlx_log.service` |
| **Dashboard** | `/var/www/html/xlxd/` |
| **Configuration** | `/var/www/html/xlxd/pgs/config.inc.php` |

---

## 🔧 Managing the Reflector

### Service Control

```bash
# Start the reflector
sudo systemctl start xlxd.service

# Stop the reflector
sudo systemctl stop xlxd.service

# Restart the reflector
sudo systemctl restart xlxd.service

# Check status
sudo systemctl status xlxd.service
```

### Real-time Monitoring

```bash
# Watch live logs
sudo tail -f /var/log/xlx.log
```

---

## 🎯 Optional Steps

### 📝 Register Your YSF Reflector

To list your reflector on YSF hosts:
1. Visit [dvref.com](https://dvref.com)
2. Follow the registration instructions

### 🔒 Manual SSL Setup

If you skipped automatic SSL during installation:
1. Visit the [Certbot website](https://certbot.eff.org)
2. Follow the simple instructions
3. Ensure TCP ports 80 and 443 are open and forwarded

---

## 🤝 Credits & Related Projects

| Project | Author | Description |
|---------|--------|-------------|
| **XLX Reflector** | [LX3JL](https://github.com/LX3JL/xlxd) | Original XLX reflector software |
| **Original Installer Idea** | [N5AMD](https://github.com/n5amd/xlxd-debian-installer) | Initial Debian installer concept |
| **YSF Registration** | [DG9VH](https://register.ysfreflector.de/) | YSF reflector registration service |
| **Echo Test Service** | [Narspt](https://github.com/narspt/XLXEcho) | XLX Echo Test implementation |
| **SSL Certification** | [Certbot](https://certbot.eff.org/) | Free SSL/TLS certificates |
| **This Installer** | [PU5KOD](https://www.qrz.com/db/PU5KOD) | Automated installation script |

---

## 📞 Support

If you encounter issues or have questions:

- 📧 Contact the maintainer: [PU5KOD](https://www.qrz.com/db/PU5KOD)
- 🐛 Open an issue on GitHub
- 💬 Join the amateur radio community discussions

---

## 📄 License

This project is open source and available for use by the amateur radio community.

---

<div align="center">

**Made with ❤️ by the Amateur Radio Community**

⭐ If you find this project useful, please consider starring it on GitHub!

</div>
