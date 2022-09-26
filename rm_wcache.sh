#!/bin/sh

# Oracle iAS WebCache autostart remove for Solaris 8,9,10,>10, Linux
# Yuri Voinov (C) 2006-2010
#
# ident "@(#)rm_wcache.sh   2.5   10/11/01 YV"
#

#############
# Variables #
#############

SVC_SHORT_NAME="wcache"
SVC2_SHORT_NAME="midtier"

SCRIPT_NAME=init.ias_"$SVC_SHORT_NAME"
SMF_XML="$SVC_SHORT_NAME".xml
SMF_XML_MID="SVC2_SHORT_NAME".xml
BOOT_DIR="/etc/init.d"
SMF_DIR="/var/svc/manifest/application/oracle"
SVC_MTD="/lib/svc/method"

CONFIG_DIR="/etc"
CONFIG_FILE_NAME1="ias_$SVC_SHORT_NAME.conf"
CONFIG_FILE1="$CONFIG_DIR/$CONFIG_FILE_NAME1"
CONFIG_FILE_NAME2="ias_$SVC2_SHORT_NAME.conf"
CONFIG_FILE2="$CONFIG_DIR/$CONFIG_FILE_NAME2"

#  
# OS Commands location variables
#
CUT=`which cut`
ECHO=`which echo`
ID=`which id`
RM=`which rm`
UNAME=`which uname`
UNLINK=`which unlink`
WHOAMI=`which whoami`

OS_VER=`$UNAME -r|$CUT -f2 -d"."`
OS_NAME=`$UNAME -s|$CUT -f1 -d" "`
OS_FULL=`$UNAME -sr`

if [ "$OS_NAME" = "SunOS" ]; then
 ZONENAME=`which zonename`
fi

ZONE=`$ZONENAME`

###############
# Subroutines #
###############

check_root ()
{
 # Check if user root
 if [ -f /usr/xpg4/bin/id ]; then
  WHO=`/usr/xpg4/bin/id -n -u`
 elif [ "`$ID | $CUT -f1 -d" "`" = "uid=0(root)" ]; then
  WHO="root"
 else
  WHO=$WHOAMI
 fi

 if [ ! "$WHO" = "root" ]; then
   $ECHO "ERROR: you must be super-user to run this script."
   exit 1
 fi
}

non_global_zones_r ()
{
 # Non-global zones notification
 if [ "$ZONE" != "global" ]; then
  $ECHO  "================================================================="
  $ECHO  "This is NON GLOBAL zone $ZONE. To complete uninstallation please remove"
  $ECHO  "script $SCRIPT_NAME" 
  $ECHO  "from $SVC_MTD"
  $ECHO  "in GLOBAL zone manually AFTER uninstalling autostart."
  $ECHO  "================================================================="
 fi
}

supported_linux ()
{
 # Check supported Linux
 # Supported Linux: RHEL3, RHEL4, SuSE, Fedora, Oracle Enterprise Linux
 if [ -f /etc/redhat-release -o -f /etc/SuSE-release -o -f /etc/fedora-release -o -f /etc/enterprise-linux ]; then
  $ECHO "1"
 else
  $ECHO "0"
 fi
}

##############
# Main block #
##############

$ECHO "#####################################################"
$ECHO "#       iAS WebCache autostart remove script        #"
$ECHO "#                                                   #"
$ECHO "# Make sure that services is stopped and disabled ! #"
$ECHO "# Press <Enter> to continue, <Ctrl+C> to cancel ... #"
$ECHO "#####################################################"
read p

# Check user root
check_root

if [ "$OS_FULL" = "SunOS 5.9" -o "$OS_FULL" = "SunOS 5.8" ]; then
 # Uninstall for OS 8,9
 $ECHO "OS: $OS_FULL"
 $UNLINK /etc/rc3.d/K01ias$SVC_SHORT_NAME>/dev/null 2>&1
 $UNLINK /etc/rc3.d/S99ias$SVC_SHORT_NAME>/dev/null 2>&1
 $RM $BOOT_DIR/$SCRIPT_NAME>/dev/null 2>&1
 $RM $CONFIG_FILE1>/dev/null 2>&1  # Remove config 1
 $RM $CONFIG_FILE2>/dev/null 2>&1  # Remove config 2
 $ECHO "-------------------- Done. ------------------------"
 $ECHO "Complete. Restart host."
elif [ "$OS_NAME" = "SunOS" ]; then
 if [ "$OS_VER" -ge "10" ]; then
  # Uninstall for OS 10
  SVCCFG=`which svccfg`
  $ECHO "OS: $OS_FULL"
  $SVCCFG delete -f /application/ias-$SVC_SHORT_NAME:default>/dev/null 2>&1
  retcode=`$ECHO $?`
  case "$retcode" in
   0) $ECHO "*** Service deleted successfuly";;
   *) $ECHO "*** Service delete operation has errors";;
  esac
  $RM $SVC_MTD/$SCRIPT_NAME>/dev/null 2>&1
  $RM $CONFIG_FILE1>/dev/null 2>&1  # Remove config 1
  $RM $CONFIG_FILE2>/dev/null 2>&1  # Remove config 2
  # If middle tier is not installed on this host, remove direcory,
  # otherwise remove XML file only
  if [ ! -f $SMF_DIR/$SMF_XML_MID ]; then
   $RM -R $SMF_DIR>/dev/null 2>&1
  else
   $RM -f $SMF_DIR/$SMF_XML>/dev/null 2>&1
  fi
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete."
  # Check for non-global zones uninstallation
  non_global_zones_r
 fi
else
 if [ "$OS_NAME" = "Linux" -a "`supported_linux`" = "1" ]; then
  # Uninstall for OS Linux
  $ECHO "OS: $OS_FULL"
  CHKCONFIG=`which chkconfig`
  $CHKCONFIG --del $SCRIPT_NAME>/dev/null 2>&1
  $CHKCONFIG --level 345 $SCRIPT_NAME off>/dev/null 2>&1
  $RM $BOOT_DIR/$SCRIPT_NAME>/dev/null 2>&1
  $RM $CONFIG_FILE1>/dev/null 2>&1  # Remove config 1
  $RM $CONFIG_FILE2>/dev/null 2>&1  # Remove config 2
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete. Restart host."
 else
  $ECHO "ERROR: Unsupported OS: $OS_FULL"
  $ECHO "Exiting..."
  exit 1
 fi
fi

exit 0