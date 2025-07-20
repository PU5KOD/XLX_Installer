# XLX Debian Installer
This project was writed by Daniel K. [PU5KOD](https://www.qrz.com/db/PU5KOD) and is inspired in the one initially created by [N5AMD](https://github.com/n5amd/xlxd-debian-installer) that facilitates the installation process of the XLX reflector developed by [LX3JL](https://github.com/LX3JL/xlxd) and many implementations have been made since then. The idea here is to offer a system that asks the user for the main information for creating the reflector as well as the respective dashboard, so when running it several variables are requested so that in the end you have an XLX reflector working without the need for intervention. Therefore what this script does is automate as many processes as possible so that the installation of the reflector and dashboard is carried out with just a few commands and with minimal user intervention. As previously mentioned, in addition to the reflector, it also installs a dashboard so you can monitor the activity in the reflector in real time, along with this, an Echo Test service (Parrot) will also be offered, it will be linked by default to Module E but can be changed later without any major problems, the service is very useful for users to be able to perform audio tests.

At the start of 2020 a new version of XLX was released that allows for native C4FM connections, this means it's even simpler to run a multi-mode reflector. The XLX now natively supports D-Star, C4FM and DMR modes, between C4FM and DMR do not require any transcoding hardware (AMBE) to work together, so if you plan to use D-Star with any of the other modes you will need hardware AMBE chips, however if your plan is just a DStar only reflector OR a YSF/DMR reflector this is not necessary.
This script always installs the latest version of the official LX3JL project (v_2.5.3 of the XLX reflector and v_2.4.2 of the dashboard at the time I write this), it has been tested and works perfectly on Debian 10, 11 and 12 (preferably on the 12) and their derivatives such as RaspiOS for Raspberry Pi, and does not require many hardware resources which can be easily run on a Raspberry Pi Zero or similar.

<b>After installing this you will have a public D-Star/YSF/DMR XLX Reflector.</b>

## Installation requirements
01.  A Debian based computer or VPS (Google VM, Amazon VPS, etc...) ready and up to date;
02.  A stable internet connection with a FIXED PUBLIC IP;
03.  Ability to manage the Firewall;
04.  Have a FQDN to dashboard, like xlx300.net;
05.  A free 3 digit XLX sufix, both numbers and letters can be used (look at the section below).

### How to find what reflectors are available:
Find a current active reflector dashboard [here](https://xlxbra.net/index.php?show=reflectors) and you will see the gaps in reflector numbers in the list, those reflector numbers not listed are available. 

## Installing the server
* First, open/redirect the ports listed at the end of this document so that no errors occur during the proper installation, then access the server terminal and run the sequence of commands below, one by one:
```sh
sudo apt install git
cd /usr/src/
sudo git clone https://github.com/PU5KOD/XLX_Installer.git
cd XLX_Installer/
sudo chmod +x *
sudo ./installer.sh
```
When running the above last command the process will start and some questions will be asked, just answer as asked, in some cases just press "ENTER" to accept the suggested answer, the questions are in the following sequence:
01. What are the 3 digits of the XLX reflector that will be used? (e.g., 300, US1, BRA)
02. What is the web address (FQDN) of the reflector dashboard? e.g., xlx.domain.com
03. What is the sysop e-mail address?
04. What is the sysop callsign?
05. What is the country of the reflector?
06. What is the comment to be shown in the XLX Reflectors list?
07. Custom text on header of the dashboard webpage
08. Do you want to install Echo Test Server? (Y/N)
09. How many active modules does the reflector have? (1-26)
10. What name will this reflector have to appear in YSF reflectors list? (max. 16 characters)
11. And what will be his description to appear on YSF reflectors list? (max. 16 characters)
12. What is the YSF UDP port number? (1-65535)
13. What is the frequency of YSF Wires-X? (In Hertz, 9 digits, e.g., 433125000)
14. Is YSF auto-link enable? (1 = Yes / 0 = No)
15. What module to be auto-link? (*)

(*) The last question will only be asked if the answer to the previous one is positive.

* After this the process of installation will be started, at the end the server will be RUNNING and ready to accept connections, however you will still need to make the firewall adjustment to redirect the ports as described below.

* If you want Reflector to be listed on YSF hosts go to [THIS](https://register.ysfreflector.de/register) website and follow the instructions for inclusion.

* If you choose to install the dashboard SSL certification yourself, check the [certbot](https://certbot.eff.org) website and follow the instructions, the procedure is simple and quick (requires TCP ports 80 and 443 already properly redirected).

### Firewall Settings:

XLX Server requires the following ports to be open and forwarded properly for in and outgoing network traffic:

* TCP port 22 (ssh)
* TCP port 80 (http)
* TCP port 443 (https)
* TCP port 8080 (RepNet) optional
* UDP port 8880 (DMR+ DMO mode)
* UDP port 10001 (json interface XLX Core)
* UDP port 10002 (XLX interlink)
* UDP port 10100 (AMBE controller port)
* UDP port 10101 - 10199 (AMBE transcoding port)
* UDP port 12345 - 12346 (ICom Terminal presence and request port)
* UPD port 20001 (DPlus protocol)
* UDP port 21110 (Yaesu IMRS protocol)
* UDP port 30001 (DExtra protocol)
* UDP port 30051 (DCS protocol)
* UDP port 40000 (Terminal DV port)
* UDP port 42000 (YSF protocol)
* UDP port 62030 (MMDVM protocol)

### Location of installation files:
 - Installs to /xlxd
 - Installation files in /usr/src/xlxd/ and /usr/src/XLXEcho/
 - Logs are in /var/log/xlxd and /var/log/messages
 - Service at /etc/init.d/xlxd and /etc/systemd/system/xlxecho.service
 - Web config file is /var/www/html/xlxd/pgs/config.inc.php
 - Dashboard files are in /var/www/html/xlxd/
 - Apache site path in /etc/apache2/sites-available/xlx*

## To interact with XLX after installation
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

## Related authors
The base projects and related authors can be found at the following links:
- Official LX3JL XLXd refletor project and install instructions, [HERE](https://github.com/LX3JL/xlxd)
- N5AMD installation script project basis, [HERE](https://github.com/n5amd/xlxd-debian-installer)
- DG9VH  Kim Huebel YSF Reflector project, [HERE](https://register.ysfreflector.de/)
- The owner of the repository that provides us with the Echo Test, [HERE](https://github.com/narspt/XLXEcho)
- Project that offers free https certification, [HERE](https://certbot.eff.org/)
- This one who speaks to you, [HERE](https://www.qrz.com/db/PU5KOD)
