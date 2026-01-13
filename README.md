# XLX Debian Installer

This project, developed by Daniel K. ([PU5KOD](https://www.qrz.com/db/PU5KOD)), builds upon the original work by [N5AMD](https://github.com/n5amd/xlxd-debian-installer) to simplify the installation of the XLX reflector, created by [LX3JL](https://github.com/LX3JL/xlxd). The script automates the setup of an XLX reflector and its accompanying dashboard, requiring minimal user intervention. It prompts for essential configuration details and handles the installation process, resulting in a fully operational multi-mode reflector supporting D-Star, C4FM, and DMR protocols. Additionally, it offers an optional Echo Test (Parrot) service, linked by default to Module E, for audio testing.

Since early 2020, XLX supports native C4FM connections, eliminating the need for AMBE transcoding hardware for C4FM and DMR interoperability. However, D-Star integration with other modes requires AMBE chips. For D-Star-only or YSF/DMR reflectors, no additional hardware is needed. The script installs the latest versions of the official XLX reflector (v2.5.3) and dashboard (v2.4.2) as of this writing, and is compatible with Debian 10, 11, and 12 (recommended), as well as derivatives like RaspiOS and Armbian. It is lightweight, suitable for low-resource devices like the Raspberry Pi Zero.

**Upon completion, you will have a fully functional public D-Star/YSF/DMR XLX reflector with a monitoring dashboard.**

## Installation Requirements

1. A Debian-based system or VPS (e.g., Google VM, Amazon EC2) with the latest updates installed.
2. A stable internet connection with a fixed public IP.
3. Firewall management capabilities to open and forward required ports.
4. A fully qualified domain name (FQDN) for the dashboard (e.g., xlxbra.net).
5. A unique 3-digit XLX suffix (numbers or letters) not currently in use.

### Finding Available Reflector Suffixes
To identify available XLX suffixes, visit the active reflector dashboard [here](https://xlxbra.net/index.php?show=reflectors). Unlisted suffixes are available for use.

## Installation Instructions

1. **Port Configuration**: Ensure the firewall ports listed in the "Firewall Settings" section are open and forwarded before proceeding.
2. Access the server terminal and execute the following commands sequentially, in the first two commands, it will update the system, then install a prerequisite, and finally begin the installation procedures:

```sh
sudo apt update
sudo apt full-upgrade
sudo apt install git
cd /usr/src/
sudo git clone https://github.com/PU5KOD/XLX_Installer.git
cd XLX_Installer/
sudo chmod +x *
sudo ./installer.sh
```

3. **Configuration Prompts**: The installer will request the following information. Respond as prompted, pressing "ENTER" to accept defaults where applicable:
   - 3-digit XLX reflector suffix (e.g., 300, US1, BRA).
   - Dashboard FQDN (e.g., xlx.domain.com).
   - Sysop email address.
   - Sysop callsign.
   - Reflector country.
   - Comment for the XLX Reflectors list.
   - Custom header text for the dashboard webpage.
   - Install Echo Test Server? (Y/N).
   - Number of active modules (1–26).
   - YSF UDP port number (1–65535).
   - YSF Wires-X frequency (in Hertz, e.g., 433125000).
   - Enable YSF auto-link? (1 = Yes / 0 = No).
   - Auto-link module (if auto-link is enabled).

4. **Completion**: The installation will proceed automatically, and upon completion, the reflector will be operational and ready to accept connections. Adjust the firewall as described below to ensure proper functionality.

5. **Dashboard Adjustment**: Until I implement the following integration with the installer, a small adjustment is still needed for the animation indicating activity in the reflector to be displayed correctly, the procedure is as follows. Adjust the commands below to the correct time zone, e.g., GMT-1, GMT0, GMT+5, etc, just remember that for Linux systems the **GMT SIGNAL IS INVERTED**, e.g., for UTC -5hs (US EST - New York, Miami, etc.), set GMT+5.
   
   ```sh
   sudo timedatectl set-timezone Etc/GMT+5
   sudo sed -i 's/^;\?date\.timezone\s*=.*/date.timezone = "Etc\/GMT+5"/' /etc/php/8.4/apache2/php.ini
   sudo systemctl reload apache2.service
   ```

6. **Optional Steps**:
   - To list your reflector on YSF hosts, visit [dvref.com](https://dvref.com) and follow the registration instructions.
   - The installation script includes an option to automatically set up SSL certification for the dashboard using Certbot. If you prefer to manually install SSL, visit the [Certbot website](https://certbot.eff.org) for simple and quick instructions. Ensure TCP ports 80 and 443 are properly opened and forwarded in your firewall before proceeding.

## Firewall Settings

The XLX reflector requires the following ports to be open and forwarded for incoming and outgoing traffic:

- **TCP**: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (RepNet, optional), 20001-20005 (DPlus protocol), 40001 (ICom G3).
- **UDP**: 8880 (DMR+ DMO mode), 10001 (JSON interface XLX Core), 10002 (XLX interlink), 10100 (AMBE controller), 10101–10199 (AMBE transcoding), 12345–12346 (ICom Terminal presence/request), 20001-20005 (DPlus protocol), 21110 (Yaesu IMRS protocol), 30001 (DExtra protocol), 30051 (DCS protocol), 40000 (Terminal DV), 42000 (YSF protocol), 62030 (MMDVM protocol).

## File and Folder Locations

- **Installation Directory**: `/xlxd/`
- **Source Folders**: `/usr/src/xlxd/`, `/usr/src/XLXEcho/`, `/usr/src/XLX_Dark_Dashboard/`, `/usr/src/XLX_Installer/`
- **Log Files**: `/var/log/xlxd*`, `/var/log/xlx.log`, `/var/log/xlxecho.log`
- **Auxiliary Files**: `/usr/local/bin/xlx_log.sh`, `/etc/logrotate.d/xlx_logrotate.conf`
- **Service Files**: `/etc/systemd/system/xlxd.service`, `/etc/systemd/system/xlxecho.service`, `/etc/systemd/system/xlx_log.service`
- **Dashboard Files**: `/var/www/html/xlxd/`
- **Apache Configuration**: `/etc/apache2/sites-available/`
- **Custom Configuration**: `/var/www/html/xlxd/pgs/config.inc.php`

## Managing the XLX Reflector

To control the reflector, use the following commands:

```sh
sudo systemctl start xlxd.service
sudo systemctl stop xlxd.service
sudo systemctl restart xlxd.service
sudo systemctl status xlxd.service
```

To monitor the reflector in real time:

```sh
sudo tail -f /var/log/xlx.log
```

## Related Projects and Authors

- Official XLX Reflector: [LX3JL](https://github.com/LX3JL/xlxd)
- Original Installation Script: [N5AMD](https://github.com/n5amd/xlxd-debian-installer)
- YSF Reflector Registration: [DG9VH](https://register.ysfreflector.de/)
- Echo Test Service: [Narspt](https://github.com/narspt/XLXEcho)
- SSL Certification: [Certbot](https://certbot.eff.org/)
- Project Maintainer: [PU5KOD](https://www.qrz.com/db/PU5KOD)
