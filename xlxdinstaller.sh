#!/bin/bash
# A tool to install XLXD, your own D-Star Reflector.
# For more information, please visit: https://n5amd.com
# Customized by Daniel K., PU5KOD
# Lets begin!!!

# root user check
if [ "$(whoami)" != "root" ]; then
  echo "You must be root to run this script!"
  exit 1
fi

# Distro check
if [ ! -e "/etc/debian_version" ]; then
  echo "This script is only tested on Debian-based distributions."
  exit 1
fi

DIRDIR=$(pwd)
LOCAL_IP=$(hostname -I | awk '{print $1}')
INFREF="https://n5amd.com/digital-radio-how-tos/create-xlx-xrf-d-star-reflector/"
XLXDREPO="https://github.com/PU5KOD/xlxd.git"
DMRIDURL="http://xlxapi.rlx.lu/api/exportdmr.php"
WEBDIR="/var/www/html/xlxd"
XLXINSTDIR="/usr/src"
APPS="git git-core make build-essential g++ apache2 php libapache2-mod-php php-cli php-xml php-mbstring php-curl"

# DATA INPUT
clear
echo "HAM Radio Multimode/Multiprotocol XLX Reflector Server"
echo ""
echo "REFLECTOR DATA INPUT"
echo "===================="
echo ""
echo "XLX uses 3 digit numbers for its reflectors. For example: 032, 999, 099."
read -p "01. What 3 digit XRF number will you be using?  " XRFDIGIT
XRFNUM=XLX$XRFDIGIT
read -p "02. What is the FQDN of the XLX Reflector dashboard? Example: xlx.domain.com.  " XLXDOMAIN
read -p "03. What E-Mail address can your users send questions to?  " EMAIL
read -p "04. What is the admins callsign?  " CALLSIGN
read -p "05. What is the Country Reflector?  " COUNTRY
read -p "06. What is the Reflector Comment to display on dashboard?  " COMMENT
# read -p "06. Custom text on header of the dashboard webpage  " HEADER
read -p "07. How many active modules does the reflector have? (1-26)  " MODQTD
read -p "08. What is the number of YSF UDP port? (1-65535)  " YSFPORT
read -p "09. What is the frequency of YSF Wires-X? (In Hertz, with 9 digits, ex. 433125000)  " YSFFREQ
read -p "10. Is YSF Auto-Link enable? (1 = Yes / 0 = No)  " AUTOLINK
VALID_MODULES=($(echo {A..Z} | cut -d' ' -f1-"$MODQTD"))
if [ "$AUTOLINK" -eq 1 ]; then
  while true; do
    read -p "11. YSF module to Auto-Link? (one of ${VALID_MODULES[*]}): " MODAUTO
    MODAUTO=$(echo "$MODAUTO" | tr '[:lower:]' '[:upper:]')
    if [[ " ${VALID_MODULES[@]} " =~ " $MODAUTO " ]]; then
      break
    else
      echo "Invalid input for YSF autolink module. Must be one of ${VALID_MODULES[*]}."
    fi
  done
fi

echo ""
echo "UPDATING OS..."
echo "=============="
echo ""

apt update && apt full-upgrade -y
mkdir -p "$XLXINSTDIR"
mkdir -p "$WEBDIR"

echo "INSTALLING DEPENDENCIES..."
echo "=========================="
echo ""

apt -y install $APPS

if [ -e "$XLXINSTDIR/xlxd/src/xlxd" ]; then
  echo "XLXD already compiled. Delete the following directories"
  echo "'/usr/src/xlxd', '/xlxd', '/var/www/html/xlxd' and the following files"
  echo "'/etc/init.d/xlxd.*', 'var/log/xlxd.*' and '/etc/apache2/sites-available/xlx*'"
  exit 1
else
  echo ""
  echo "DOWNLOADING APPLICATION..."
  echo "=========================="
  echo ""
  cd "$XLXINSTDIR"
  git clone "$XLXDREPO"
  cd "$XLXINSTDIR/xlxd/src"
  make clean
  MAINCONFIG="$XLXINSTDIR/xlxd/src/main.h"
  sed -i "s/\(NB_OF_MODULES\s*\)\([0-9]*\)/\1$MODQTD/" "$MAINCONFIG"
  sed -i "s/\(YSF_PORT\s*\)\([0-9]*\)/\1$YSFPORT/" "$MAINCONFIG"
  sed -i "s/\(YSF_DEFAULT_NODE_TX_FREQ\s*\)\([0-9]*\)/\1$YSFFREQ/" "$MAINCONFIG"
  sed -i "s/\(YSF_DEFAULT_NODE_RX_FREQ\s*\)\([0-9]*\)/\1$YSFFREQ/" "$MAINCONFIG"
  sed -i "s/\(YSF_AUTOLINK_ENABLE\s*\)\([0-9]*\)/\1$AUTOLINK/" "$MAINCONFIG"
  if [ "$AUTOLINK" -eq 1 ]; then
    sed -i "s/\(YSF_AUTOLINK_MODULE\s*\)'\([A-Z]*\)'/\1'$MODAUTO'/" "$MAINCONFIG"
  fi
  echo ""
  echo "COMPILING..."
  echo "============"
  echo ""
  make
  make install
fi

if [ -e "$XLXINSTDIR/xlxd/src/xlxd" ]; then
  echo ""
  echo "==============================="
  echo "|  COMPILATION SUCCESSFUL!!!  |"
  echo "==============================="
  echo ""
else
  echo ""
  echo "======================================================"
  echo "|  Compilation FAILED. Check the output for errors.  |"
  echo "======================================================"
  echo ""
  exit 1
fi

mkdir -p /xlxd
wget -O /xlxd/dmrid.dat "$DMRIDURL"

cp -R "$XLXINSTDIR/xlxd/dashboard/"* "$WEBDIR/"
cp "$XLXINSTDIR/xlxd/scripts/xlxd" /etc/init.d/xlxd
sed -i "s/XLXXXX 172.23.127.100 127.0.0.1/$XRFNUM $LOCAL_IP 127.0.0.1/g" /etc/init.d/xlxd
update-rc.d xlxd defaults

XLXCONFIG="$WEBDIR/pgs/config.inc.php"
sed -i "s/your_email/$EMAIL/g" "$XLXCONFIG"
sed -i "s/LX1IQ/$CALLSIGN/g" "$XLXCONFIG"
# sed -i "s/custom_header/$HEADER/g" "$XLXCONFIG"
sed -i "s#http://your_dashboard#http://$XLXDOMAIN#g" "$XLXCONFIG"
sed -i "s/your_country/$COUNTRY/g" "$XLXCONFIG"
sed -i "s/your_comment/$COMMENT/g" "$XLXCONFIG"
sed -i "s#/tmp/callinghome.php#/xlxd/callinghome.php#g" "$XLXCONFIG"
sed -i "s#/tmp/lastcallhome.php#/xlxd/lastcallhome.php#g" "$XLXCONFIG"

cp "$DIRDIR/templates/apache.tbd.conf" /etc/apache2/sites-available/"$XLXDOMAIN".conf
sed -i "s/apache.tbd/$XLXDOMAIN/g" /etc/apache2/sites-available/"$XLXDOMAIN".conf
sed -i "s#ysf-xlxd#html/xlxd#g" /etc/apache2/sites-available/"$XLXDOMAIN".conf

chown -R www-data:www-data "$WEBDIR/"
chown -R www-data:www-data /xlxd/

a2ensite "$XLXDOMAIN".conf
a2dissite 000-default
systemctl restart apache2
systemctl start xlxd

echo "=============================================================================================="
echo "$XRFNUM is now installed and ready to use."
echo "For Public Reflectors:"
echo "If your XLX number is available it is expected to be listed"
echo "on the public list shortly, typically within an hour."
echo "If you do not want the Reflector to be published just set callinghome"
echo "to false in the main file in $XLXCONFIG."
echo "Many other settings can be changed in this file."
echo "More Information: $INFREF"
echo "Your $XRFNUM dashboard should now be accessible at http://$XLXDOMAIN"
echo "To get your site on https:// visit certbot.eff.org"
echo "=============================================================================================="
