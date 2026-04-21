# 🌐 XLX Debian Installer - Documentation

<div align="center">

![XLX Version](https://img.shields.io/badge/XLX-v2.5.3-blue)
![Dashboard Version](https://img.shields.io/badge/Dashboard-3.2.1-blue)
![Debian](https://img.shields.io/badge/Debian-10%2B-red)
![License](https://img.shields.io/badge/license-MIT-green)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)

**Automated installation script for XLX multi-mode reflectors**  
Supporting D-Star • C4FM • DMR protocols

[Features](#-features) • [Quick Start](#-quick-start) • [Installation](#-installation-process) • [Configuration](#%EF%B8%8F-firewall-configuration) • [User Manager](#-user-manager)

</div>

---

## 📖 About the Project

This project simplifies the installation of XLX reflectors with minimal user intervention. Developed by **Daniel K. ([PP5PK](https://www.qrz.com/db/PP5PK))**, this installer automates the setup of the XLX reflector created by [LX3JL](https://github.com/LX3JL/xlxd) and includes a customized dark theme dashboard. The goal is to make deploying an XLX reflector **easy, reliable, and maintainable**!

**Upon completion, you'll have a fully functional public D-Star/YSF/DMR XLX reflector with monitoring dashboard!** 🎉

### 🎯 Key Highlights

- ✅ **No AMBE hardware needed** for C4FM and DMR interoperability (since early 2020)
- ✅ **Complete systemd service integration** replacing legacy init.d scripts
- ✅ **Dark theme dashboard** with improvements and modern UI
- ✅ **Lightweight** - it ever runs on Raspberry Pi Zero!
- ✅ **Optional Echo Test** (Parrot) service to audio tests
- ✅ **Compatible** with Debian 10+ (13 recommended), Ubuntu, RaspiOS, Armbian, etc...
- ✅ **Full uninstall support**
- ✅ **Built-in User Manager** for whitelist, dashboard access and RadioID database

> **Note:** D-Star integration with other modes still requires AMBE chips. For D-Star-only or YSF/DMR reflectors, no additional hardware is needed.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 **Multi-Protocol** | Native support for D-Star, C4FM (YSF), and DMR |
| 🎨 **Custom Dashboard** | Dark theme with enhanced monitoring capabilities |
| 🔊 **Echo Test** | Optional Parrot service for audio testing |
| 🔒 **SSL Ready** | Automated SSL certificate setup with Certbot |
| 📊 **Real-time Monitoring** | Live connection tracking and statistics |
| 🌍 **YSF Auto-link** | Configurable automatic linking for YSF |
| 🎯 **Auto-update** | Automatic real-time users database setup |
| 👥 **User Manager** | Terminal tool to manage users, whitelist and passwords |

### ✔ Dashboard Features
The included dashboard is a dark-theme fork with major improvements:

- Real-time multi-TX module detection with pulsing highlight animation and live TX timers
- Live duration counter for connected stations, updating every second without page reload
- Responsive layout for desktop and mobile
- 30‑day activity history and module activity chart (via Chart.js, independent 60-second refresh)
- SQLite operator database (call, name, city) displayed in Recent Activity and Connected Stations tabs
- Filter-aware auto-refresh — pauses when a callsign or module filter is active
- Browser tab badge showing connected station count and active TX callsign
- Hidden tabs support and others via `config.inc.php`

### ✔ Systemd Integration
The installer provides native **systemd services**, replacing original XLXD `init.d` behavior:

- `xlxd.service`
- `xlx_log.service`
- `update_XLX_db.service` (update timers)
- `xlxecho.service` (if Echo Test is enabled)

This brings better reliability, logging, restart behavior, and dependency control.

---

## 📋 Requirements

Before installation, ensure you have:

- [x] Debian-based system or VPS with latest updates
- [x] Stable internet connection with **fixed public IP**
- [x] Firewall management capabilities
- [x] **FQDN** for dashboard (e.g., `xlxbra.net`)
- [x] Unique **3-digit XLX ID** (check availability [here](https://xlxbra.net/index.php?show=reflectors))

### 🔍 Finding Available Reflector Suffixes

Visit any active reflector dashboard to see which XLX suffixes are in use. Any unlisted suffix is available!

---

## 📦 Installation process

### Step 1: Configure Firewall Ports

**Before running the installer**, ensure all required ports are open and forwarded (see [Firewall Configuration](#-firewall-configuration)).

### Step 2: Run Installation

Execute the commands from the [Quick Start](#-quick-start) section above.

### Step 3: Configuration Prompts

The installer will request the following information:

| # | Prompt | Example | Default |
|---|--------|---------|---------|
| 01 | 3-digit XLX reflector | `300`, `US1`, `BRA` | - |
| 02 | Dashboard FQDN | `xlxbra.net` | - |
| 03 | Sysop email address | `xlxref@gmail.com` | - |
| 04 | Sysop callsign | `PP5PK` | - |
| 05 | Reflector country | `Germany` | - |
| 06 | Time Zone | `Europe/Berlin` | Detected |
| 07 | Comment for XLX list | `XLX300 Reflector...` | - |
| 08 | Custom tab name | `XLXBRA Dashboard...` | - |
| 09 | Custom footnote | `Maintained by...` | - |
| 10 | Install SSL? | `Y/N` | Y |
| 11 | Install Echo Test? | `Y/N` | Y |
| 12 | Number of modules | `1-26` | 5 |
| 13 | YSF UDP port | `1-65535` | 42000 |
| 14 | YSF Wires-X frequency (Hz) | `433125000` | 433125000 |
| 15 | Enable YSF auto-link? | `Y/N` | Y |
| 16 | YSF auto-link module | `A-Z` | C |

### Step 4: Completion ✅

The installation proceeds automatically. Once complete, your reflector will be operational and ready to accept connections!

---

## 🚀 Quick Start

```bash
# Update system
sudo apt update && sudo apt full-upgrade -y

# Install prerequisites
sudo apt install git -y

# Clone repository
cd /usr/src/
sudo git clone https://github.com/PP5PK/XLX_Installer.git

# Run installer
cd XLX_Installer/ && sudo chmod +x *.sh
sudo ./installer.sh
```

---

## 🛡️ Firewall Configuration

### Required Open Ports

| Port | Type | Description |
|---------|-----|---------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 8080 | TCP | RepNeT |
| 20001-20005 | TCP | DPlus protocol |
| 40001 | TCP | ICom G3 |
| 8880 | UDP| DMR+ DMO mode |
| 10001 | UDP | JSON interface XLX Core |
| 10002 | UDP | XLX interlink |
| 10100 | UDP | AMBE controller |
| 10101-10199 | UDP | AMBE transcoding |
| 12345-12346 | UDP | ICom Terminal presence/request |
| 20001-20005 | UDP | DPlus protocol |
| 21110 | UDP | Yaesu IMRS protocol |
| 30001 | UDP | DExtra protocol |
| 30051 | UDP | DCS protocol |
| 40000 | UDP | Terminal DV |
| 42000 | UDP | YSF protocol |
| 62030 | UDP | MMDVM protocol |

---

## 📂 File Locations

| Type | Location |
|------|----------|
| **Installation** | `/xlxd/` |
| **Source Folders** | `/usr/src/xlxd/`<br>`/usr/src/XLXEcho/`<br>`/usr/src/XLX_Dark_Dashboard/`<br>`/usr/src/XLX_Installer/` |
| **Log Files** | `/var/log/xlxd*`<br>`/var/log/xlx.log`<br>`/var/log/xlxecho.log`<br>`/usr/local/bin/xlx_log.sh`<br>`/etc/logrotate.d/xlx_logrotate.conf` |
| **Services** | `/etc/systemd/system/xlxd.service`<br>`/etc/systemd/system/xlxecho.service`<br>`/etc/systemd/system/xlx_log.service`<br>`update_XLX_db.service`<br>`update_XLX_db.timer` |
| **Dashboard** | `/var/www/html/xlxd/` |
| **Configuration** | `/var/www/html/xlxd/pgs/config.inc.php` |
| **User Manager** | `/xlxd/users_db/reflector_user_manager.sh` |
| **RadioID Database** | `/xlxd/users_db/users_base.csv` |
| **Whitelist** | `/xlxd/xlxd.whitelist` |
| **Dashboard Access** | `/var/www/restricted/.htpasswd` |

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

## 👥 User Manager

The installer includes `reflector_user_manager.sh`, a unified terminal tool for all user administration tasks. Instead of running separate scripts, everything is available from a single two-level interactive menu.

```bash
sudo /xlxd/users_db/reflector_user_manager.sh
```

### Menu Structure

```
Main menu
├── 1) Database (RadioID)
│   ├── 1) Add / Edit record
│   ├── 2) Delete record
│   ├── 3) List records by Callsign
│   ├── 4) Search records (filter)
│   ├── 5) Create / Update SQL database
│   └── X) Back
└── 2) Access Control
    ├── 1) Add user       (whitelist + dashboard)
    ├── 2) Reset password (dashboard)
    ├── 3) Remove user    (whitelist + dashboard)
    ├── 4) Look up user   (whitelist + dashboard)
    ├── 5) List pending   (password not yet changed)
    ├── 6) List whitelist (all callsigns)
    └── X) Back
```

### Key Capabilities

| Feature | Description |
|---------|-------------|
| 📋 **RadioID Database** | Add, edit, delete and search records in `users_base.csv` |
| 🔍 **Filtered Search** | Case-insensitive partial search by callsign, DMRID, name, city or country — with pagination (25 records/page) |
| 🔑 **Password Management** | Generate and reset secure 12-character dashboard passwords |
| 📡 **Whitelist Control** | Add and remove callsigns from `xlxd.whitelist` with confirmation |
| 🗂️ **Whitelist Listing** | Display all active whitelist entries in auto-sized columns |
| ⏳ **Pending List** | Track users who have not yet changed their initial password |
| 🔄 **SQL Sync** | Trigger `create_user_db.php` to rebuild the SQLite database from the CSV |

> For full documentation see [REFLECTOR_USER_MANAGER.md](REFLECTOR_USER_MANAGER.md).

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

## 🧹 Uninstall (Full Removal)

To remove *all traces* of the installation:

```bash
cd /usr/src/xlx_installer
sudo ./uninstaller.sh
```

This removes:

- systemd services  
- dashboard  
- reflector core  
- config files  
- Apache integration  
- cron/timers  
- logs  
- directories  

No leftovers.

---

## 🤝 Credits & Related Projects

| Project | Author | Description |
|---------|--------|-------------|
| **XLX Reflector** | [LX3JL](https://github.com/LX3JL/xlxd) | Original XLX reflector software |
| **XLX Forum Home** | [LX1IQ](https://xlxbbs.epf.lu) | Official XLX Forum / Support |
| **XLX Dark Dashboard** | [PP5PK](https://github.com/PP5PK/XLX_Dark_Dashboard) | Dark themed XLX dashboard |
| **Original Installer Idea** | [N5AMD](https://github.com/n5amd/xlxd-debian-installer) | Initial Debian installer concept |
| **YSF Registration** | [KC1AWV](https://dvref.com) | YSF Reflector registration service |
| **Echo Test Service** | [Narspt](https://github.com/narspt/XLXEcho) | XLX Echo Test implementation |
| **SSL Certification** | [Certbot](https://certbot.eff.org/) | Free SSL/TLS certificates |
| **This Installer** | [PP5PK](https://www.qrz.com/db/PP5PK) | Automated installation script |

---

## 📞 Support

If you encounter issues or have questions:

- 📧 Contact the maintainer: [PP5PK](https://www.qrz.com/db/PP5PK)
- 🐛 Open an issue on GitHub
- 💬 Join the amateur radio community discussions

---

## 📄 License

This project is open source and available for use by the amateur radio community.
MIT License – free to use and modify.

---

## ⭐ Community Support

<div align="center">

**Made with ❤️ by the Amateur Radio Community**

⭐ If you find this project useful, please consider starring it on GitHub!
Contributions and pull requests are welcome.

</div>
