# XLX Debian Installer
This project was writed by Daniel K. (PU5KOD) and is a fork of the one initially created by N5AMD that facilitates the installation process of the XLX reflector developed by LX3JL and many implementations have been made since then. The idea here is to offer a system that asks the user for the main information for creating the reflector as well as the respective dashboard, so when running it several variables are requested so that in the end you have an XLX reflector working without the need for intervention. Therefore what this script does is automate as many processes as possible so that the installation of the reflector and dashboard is carried out with just a few commands and with minimal user intervention. As previously mentioned, in addition to the reflector, it also installs a dashboard so you can monitor the activity in the reflector in real time.
After installing this you will have a public D-Star/DMR/YSF XLX Reflector.

The base projects can be found at the following links:
- Official LX3JL refletor project and install instructions, [HERE](https://github.com/LX3JL/xlxd).
- N5AMD installation script project basis, [HERE](https://github.com/n5amd/xlxd-debian-installer)

At the start of 2020 a new version of XLX was released that allows for native C4FM connections, this means it's even simpler to run a multi-mode reflector. The XLX now natively supports D-Star, C4FM and DMR modes, C4FM and DMR do not require any transcoding hardware (AMBE) to work together, so if you plan to use D-Star with any of the other modes you will need hardware AMBE chips, however if your plan is just a DStar only reflector or a YSF/DMR reflector this is not necessary.
This script always installs the latest version of the official LX3JL project because the installation source is the same (v_2.5.3 of the XLX reflector and v_2.4.2 of the dashboard at the time I write this), it has been tested and works perfectly on Debian 10, 11 and 12 and their derivatives such as RaspiOS for Raspberry Pi, and does not require many hardware resources which can be easily run on a Raspberry Pi Zero or similar.

### Installation requirements:
01.  A Debian based computer or VPS (Google VM, Amazon VPS, etc...) ready and up to date;
02.  A stable internet connection with a fixed public IP;
03.  Ability to manage the Firewall to redirect ports;
04.  Have a FQDN to dashboard, like xlx300.net;
05.  A free 3 digit XLX sufix, both numbers and letters can be used (look at the section below);
06.  An administrator e-mail address;
07.  An administrator gateway callsign;
08.  How many modules will be activated;
09.  An YSF UDP port to be used;
10.  Wires-X gateway frequency.

### How to find what reflectors are available:
Find a current active reflector dashboard [here](https://xlx300.net/index.php?show=reflectors) and you will see the gaps in reflector numbers in the list, those reflector numbers not listed are available. 

### Installing the server:
Access the server terminal and run the sequence of commands below:
```sh
cd
sudo git clone https://github.com/PU5KOD/xlxd_installer.git
cd xlxd_installer
sudo bash xlxdinstaller.sh
```
When running the above last command the process will start and some questions will be asked, in the following sequence:
1. What are the 3 digits of the XLX reflector that will be used?
2. What is the web address (FQDN) of the Reflector dashboard? Example: xlx.domain.com
3. To what e-mail address your users can send questions to?
4. What is the Reflector administrator’s callsign?
5. Which country of the reflector?
6. How many active modules does the reflector have? (1-26)
7. What is the YSF UDP port number? (default 42000)
8. What is the frequency of YSF Wires-X? (In Hertz, with 9 digits, ex. 433125000)
9. Is YSF auto-link enable? (1 = Yes / 0 = No)
10. What YSF module to be auto-link? (*)

(*) The last question will only be asked if the answer to the previous one is positive.

After this the process of installation will be started, at the end the server will already be ready to run, you will be able to interact with it as demonstrated below.

### To interact with xlxd after installation:
To <b>start</b>, <b>stop</b>, <b>restart</b>, or verify the <b>status</b> of the application use one of the corresponding commands:
```sh
sudo systemctl start xlxd.service
sudo systemctl stop xlxd.service
sudo systemctl restart xlxd.service
sudo systemctl status xlxd.service
```
And to check the process by running live use the command below:
```sh
sudo journalctl -u xlxd.service -f -n 50
```

### Location of installation files:
 - Installs to /xlxd
 - Installation files in /usr/src/xlxd/
 - Logs are in /var/log/xlxd and /var/log/messages
 - Service at /etc/init.d/xlxd
 - Web config file is /var/www/html/xlxd/pgs/config.inc.php
 - Dashboard files are in /var/www/html/xlxd/
 - Apache site path in /etc/apache2/sites-available/xlx*

## Firewall Settings:

XLX Server requires the following ports to be open and forwarded properly for in- and outgoing network traffic:

* TCP port 22 (ssh)
* TCP port 80 (http) *
* TCP port 443 (https)
* TCP port 8080 (RepNet) optional
* UDP port 8880 (DMR+ DMO mode)
* UDP port 10001 (json interface XLX Core) *
* UDP port 10002 (XLX interlink) *
* TCP port 10022 (Remote) optional
* UDP port 10100 (AMBE controller port)
* UDP port 10101 - 10199 (AMBE transcoding port)
* UDP port 12345 - 12346 (ICom Terminal presence and request port) *
* UPD port 20001 (DPlus protocol) *
* UDP port 21110 (Yaesu IMRS protocol)
* UDP port 30001 (DExtra protocol) *
* UDP port 30051 (DCS protocol) *
* UDP port 40000 (Terminal DV port) *
* UDP port 42000 (YSF protocol)
* UDP port 62030 (MMDVM protocol)

Ports marked with * are mandatory.
