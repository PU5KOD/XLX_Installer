# xlxd-debian-installer
This project is a derivation of the one initially created by N5AMD that facilitates the installation process of the XLX reflector developed by LX3JL. What this script does is automate as many processes as possible so that the installation of the reflector and its respective dashboard are executed with just a few commands and with minimal user intervention. As previously mentioned, in addition to the reflector, it also installs a dashboard so that you can monitor the activity in the reflector in real time.
After installing this you will have a private or public D-Star, DMR, and YSF XLX Reflector.

The original projects can be found at the following links:
- Official refletor project and install instructions, [HERE](https://github.com/LX3JL/xlxd).
- Installation script project basis, [HERE](https://github.com/n5amd/xlxd-debian-installer)

At the start of 2020 a new version of XLX was released that allows for native C4FM connections. This means it's even simpler to run a multi-mode reflector. XLX now natively supports D-Star, C4FM and DMR. C4FM and DMR do not require any transcoding hardware (AMBE) to work together. If you plan on using D-Star with any of the other modes, you will need hardware AMBE chips.
This script installs version 2.5.3 of the XLX reflector and version 2.4.2 of the dashboard, it has been tested and works perfectly on Debian 10, 11 and 12 and their derivatives, such as RaspiOS for Raspberry Pi and does not require many hardware resources, and can be easily run on a Raspberry Pi Zero or similar.

### To Install:
1. Have a fresh Debian based computer ready and up to date;
2. Have a stable internet connection and a fixed public IP;
3. Ability to redirect some ports to the server;
4. Have both a FQDN like xlx300.net;
5. A free 3 digit XLX number;
6. An e-mail address and gateway callsign;
7. Number of active modules;
8. YSF UDP port and Wires-X GW frequency.
   
```sh
cd
sudo git clone https://github.com/PU5KOD/xlxd_installer.git
cd xlxd_installer
sudo bash xlxdinstaller.sh
```
## How to find what reflectors are available
Find a current active reflector dashboard, for example, https://xlx300.net/index.php?show=modules and you will see the gaps in reflector numbers in the list, those reflector numbers not listed are available. 

### To interact with xlxd after installation:
```sh
sudo systemctl start|stop|status|restart xlxd.service
journalctl -u xlxd.service -f -n 50
```
 - Installs to /xlxd
 - Logs are in /var/log/messages and *'systemctl status xlxd'*
 - Main config file is /var/www/html/pgs/config.inc.php
 - Be sure to restart xlxd after each config change *'sudo systemctl restart xlxd.service'*

## Firewall Settings:

XLX Server requires the following ports to be open and forwarded properly for in- and outgoing network traffic:

* (*) TCP port 80 (http);
* (*) TCP port 443 (https);
* TCP port 8080 (RepNet) optional;
* (*) UDP port 10001 (json interface XLX Core);
* (*) UDP port 10002 (XLX interlink);
* TCP port 22 (ssh);
* TCP port 10022 (Remote) optional;
* UDP port 42000 (YSF protocol);
* (*) UDP port 30001 (DExtra protocol);
* (*) UPD port 20001 (DPlus protocol);
* (*) UDP port 30051 (DCS protocol);
* UDP port 8880 (DMR+ DMO mode);
* (*) UDP port 62030 (MMDVM protocol);
* UDP port 10100 (AMBE controller port);
* UDP port 10101 - 10199 (AMBE transcoding port);
* UDP port 12345 - 12346 (Icom Terminal presence and request port);
* UDP port 40000 (Terminal dv port);
* UDP port 21110 (Yaesu IMRS protocol);

Ports marked with * are mandatory.
