# xlxd-debian-installer
This script simply runs through the official install instructions found [HERE](https://github.com/LX3JL/xlxd). The script will install XLX along with setting up the web dashboard to view real-time activity. After installing this you will have a private or public D-Star, DMR, and YSF XLX Reflector.

At the start of 2020 a new version of XLX was released that allows for native C4FM connections. This means it's even simpler to run a multi-mode reflector. XLX now natively supports DMR, D-Star, and C4FM. C4FM and DMR do not require any transcoding hardware (AMBE) to work together. If you plan on using D-Star with any of the other modes, you will need hardware AMBE chips.


### To Install:
1. Have a fresh Debian computer ready and up to date.
2. Have both a FQDN like xlxxxx.net;
3. A 3 digit XLX number in mind before beginning;
4. An e-mail address and gateway callsign;
5. Number of active modules;
6. YSF UDP port and Wires-X GW frequency.
   
```sh
cd
sudo git clone https://github.com/PU5KOD/xlxd_installer.git
cd xlxd_installer
sudo bash xlxdinstaller.sh
cd /var/www/
sudo mv xlxd/ html/
```
## How to find what reflectors are available
Find a current active reflector dashboard, for example, https://xlx.n5amd.com/index.php?show=reflectors and you will see the gaps in reflector numbers in the list. Those reflector numbers not listed are available. 

### To interact with xlxd after installation:
```sh
sudo systemctl start|stop|status|restart xlxd.service
journalctl -u xlxd.service -f -n 50
```
 - Installs to /xlxd
 - Logs are in /var/log/messages and *'systemctl status xlxd'*
 - Main config file is /var/www/html/pgs/config.inc.php
 - Be sure to restart xlxd after each config change *'sudo systemctl restart xlxd.service'*

**For more information, please visit:**

https://n5amd.com/digital-radio-how-tos/create-xlx-xrf-d-star-reflector/
