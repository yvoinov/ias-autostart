#!/bin/sh

# Oracle iAS Infrastructure autostart setup for Solaris 8,9,10,>10, Linux
# Yuri Voinov (C) 2006-2010
#
# ident "@(#)inst_infra.sh    2.5   10/11/01 YV"
#

#############
# Variables #
#############

SVC_SHORT_NAME="infra"

SCRIPT_NAME=init.ias_"$SVC_SHORT_NAME"
SMF_XML="$SVC_SHORT_NAME".xml
BOOT_DIR="/etc/init.d"
SMF_DIR="/var/svc/manifest/application/oracle"
SVC_MTD="/lib/svc/method"
TMP="/tmp"

INST_CONFIG_FILE="inst_infra.conf"

CONFIG_DIR="/etc"
CONFIG_FILE_NAME="ias_$SVC_SHORT_NAME.conf"
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"

#   
# OS Commands location variables
#
CAT=`which cat`
CHMOD=`which chmod`
CHOWN=`which chown`
CP=`which cp`
CUT=`which cut`
ECHO=`which echo`
GREP=`which grep`
ID=`which id`
LN=`which ln`
LS=`which ls`
MKDIR=`which mkdir`
SED=`which sed`
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

check_install_files ()
{
 # Check needful installation files exists
 if [ ! -f $SMF_XML -a ! -f $SCRIPT_NAME -a ! -f $CONFIG_FILE_NAME -a ! -f $INST_CONFIG_FILE ]; then
  $ECHO "One or more installation files not found."
  $ECHO "Exiting..."
  exit 1
 fi
}

get_config_parameters ()
{
 # Check if install config exists
 if [ ! -f "$INST_CONFIG_FILE" ]; then
  $ECHO "Config file $INST_CONFIG_FILE not found. Exiting..."
  exit 1
 else
  # Load install config file into environment
  . $INST_CONFIG_FILE
 fi
}

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

copy_init ()
{
 # Copy init script function
 SC_NAME=$1
 NON_10_OS=$2

 if [ "$NON_10_OS" = "1" ]; then
  if [ ! -f $BOOT_DIR/$SC_NAME ]; then
   $CP $SC_NAME $BOOT_DIR/$SC_NAME>/dev/null 2>&1
  fi
 else
  if [ ! -f $SVC_MTD/$SC_NAME ]; then
   $CP $SC_NAME $SVC_MTD>/dev/null 2>&1
  fi
 fi

 # Copy config file
 $CP $CONFIG_FILE_NAME $CONFIG_DIR>/dev/null 2>&1
 $CHOWN $ORACLE_OWNER:$ORACLE_GROUP $CONFIG_FILE
}

link_rc ()
{
 # Link legacy RC scripts
 SC_NAME=$1
 SINGLE=$2

 if [ ! -z "$SINGLE" ]; then
  # Solaris single host installation issue. 
  # If both scripts is found, midtier must shutdown before infrastructure.
  $UNLINK /etc/rc3.d/K02ias$SVC_SHORT_NAME>/dev/null 2>&1
  $UNLINK /etc/rc3.d/S99ias$SVC_SHORT_NAME>/dev/null 2>&1
  $LN -s $BOOT_DIR/$SC_NAME /etc/rc3.d/K02ias$SVC_SHORT_NAME
  $LN -s $BOOT_DIR/$SC_NAME /etc/rc3.d/S99ias$SVC_SHORT_NAME
 else
  $UNLINK /etc/rc3.d/K01ias$SVC_SHORT_NAME>/dev/null 2>&1
  $UNLINK /etc/rc3.d/S99ias$SVC_SHORT_NAME>/dev/null 2>&1
  $LN -s $BOOT_DIR/$SC_NAME /etc/rc3.d/K01ias$SVC_SHORT_NAME
  $LN -s $BOOT_DIR/$SC_NAME /etc/rc3.d/S99ias$SVC_SHORT_NAME
 fi
}

check_group_dba ()
{
 # Check oracle main group exists
 par_group=$1
 GR_NAME=`$CAT /etc/group|$GREP $par_group|$CUT -f1 -d":"`

 if [ "$GR_NAME" != "$par_group" ]; then
  $ECHO "ERROR: Group $par_group does not exists. Make sure Oracle software installed."
  $ECHO "Exiting..."
  exit 1
 fi
}

make_smf ()
{
 # Make SMF entry
 SVCCFG=`which svccfg`

 if [ ! -d $SMF_DIR ]; then
  $MKDIR $SMF_DIR
 fi
 $CP $SMF_XML $SMF_DIR
 $CHOWN -R root:sys $SMF_DIR
 $SVCCFG validate $SMF_DIR/$SMF_XML>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** XML service descriptor validation successful";;
  *) $ECHO "*** XML service descriptor validation has errors";;
 esac
 $SVCCFG import $SMF_DIR/$SMF_XML>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** XML service descriptor import successful";;
  *) $ECHO "*** XML service descriptor import has errors";;
 esac
}

verify_svc ()
{
 # Installed service verification
 SC_NAME=$1

 $ECHO "------------ Service verificstion ----------------"
 if [ "$OS_FULL" = "SunOS 5.9" -o "$OS_FULL" = "SunOS 5.8" ]; then
  $LS -al /etc/rc3.d/*ias*
 elif [ "$OS_NAME" = "SunOS" -a "$OS_VER" -ge "10" ]; then
  SVCS=`which svcs`
  $LS -al $SVC_MTD/$SC_NAME
  $LS -l $SMF_DIR
  $SVCS ias-$SVC_SHORT_NAME
 else
  $LS -al /etc/rc3.d/*ias*
  $LS -al /etc/rc0.d/*ias*
 fi
 $LS -al $CONFIG_FILE
}

non_global_zones ()
{
 # Non-global zones notification
 if [ "$ZONE" != "global" ]; then
  $ECHO "=============================================================="
  $ECHO "This is NON GLOBAL zone $ZONE. To complete installation please copy"
  $ECHO "script $SCRIPT_NAME" 
  $ECHO "to $SVC_MTD"
  $ECHO "in GLOBAL zone manually BEFORE starting service by SMF."
  $ECHO "Note: Permissions on $SCRIPT_NAME must be set to root:sys."
  $ECHO "============================================================="
 fi
}

supported_linux ()
{
 # Check supported Linux
 # Supported Linux: RHEL3, RHEL4, SuSE, Fedora, Oracle Enterprise Linux
 if [ -f /etc/redhat-release -o -f /etc/SuSE-release -o -f /etc/fedora-release -o -f /etc/enterprise-release ]; then
  $ECHO "1"
 else
  $ECHO "0"
 fi
}

oratab_autostart_enable ()
{
 # Enabling autostart in oratab file
 # Try to find an oratab file
 if [ -z "$ORATAB" ]; then
  if [ -f /var/opt/oracle/oratab ]; then
   ORATAB="/var/opt/oracle/oratab"      # Solaris-type location
  elif [ -f /etc/oratab ]; then
   ORATAB="/etc/oratab"                 # Linux/HPUX-type location
  else
   $ECHO "ERROR: Could not find oratab file."
  fi
 elif [ ! -f $ORATAB ]; then
  $ECHO "ERROR: Could not find oratab: $ORATAB"
 fi

 # Enable all specified ORACLE_SID in oratab, 
 # leave disabled all others '*'-marked SID's

 # Old code
 #$SED -e 's/.$//' -e 's/^[a-zA-Z0-9_-]*:.*:/&Y/g' -e 's/^*:.*:/&N/g' $ORATAB>$TMP/oratmp && mv $TMP/oratmp $ORATAB
 # New code
 $SED -e 's/^[a-zA-Z0-9_+-]*:.*:/&Y/' -e 's/^\*:.*:/&N/' -e 's/YN/Y/' -e 's/NN/N/' $ORATAB>$TMP/oratmp && mv $TMP/oratmp $ORATAB

 # Maintenance return code
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** Autostart flag in $ORATAB enabled.";;
  *) $ECHO "*** Enabling autostart in $ORATAB has errors.";;
 esac
}

##############
# Main block #
##############

# Get single host parameter from command line if present
SINGLE_HOST=$1

$ECHO "#####################################################"
$ECHO "#      iAS Infra autostart installation script      #"
$ECHO "#                                                   #"
$ECHO "# Press <Enter> to continue, <Ctrl+C> to cancel ... #"
$ECHO "#####################################################"
read p

# Check user root
check_root

# Check installation files
check_install_files

# Get installation config
get_config_parameters

if [ "$OS_FULL" = "SunOS 5.9" -o "$OS_FULL" = "SunOS 5.8" ]; then
 # Install for SunOS 8,9
 $ECHO "OS: $OS_FULL"
 copy_init $SCRIPT_NAME 1
 check_group_dba $ORACLE_GROUP
 $CHOWN root:dba $BOOT_DIR/$SCRIPT_NAME
 $CHMOD 755 $BOOT_DIR/$SCRIPT_NAME
 link_rc $SCRIPT_NAME $SINGLE_HOST
 # Verify installation
 verify_svc $SCRIPT_NAME
 # Enabling autostart in oratab
 oratab_autostart_enable
 $ECHO "-------------------- Done. ------------------------"
 $ECHO "Complete. Check $SCRIPT_NAME working and if true,"
 $ECHO "restart host to verify."
elif [ "$OS_NAME" = "SunOS" ]; then 
 if [ "$OS_VER" -ge "10" ]; then
  # Install for SunOS 10 and above
  $ECHO "OS: $OS_FULL"
  copy_init $SCRIPT_NAME 0
  $CHOWN root:sys $SVC_MTD/$SCRIPT_NAME
  $CHMOD 755 $SVC_MTD/$SCRIPT_NAME
  make_smf
  # Verify installation
  verify_svc $SCRIPT_NAME
  # Enabling autostart in oratab
  oratab_autostart_enable
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete. Check $SCRIPT_NAME working and if true,"
  $ECHO "enable service by svcadm."
  # Check for non-global zones installation
  non_global_zones
 fi
else
 if [ "$OS_NAME" = "Linux" -a "`supported_linux`" = "1" ]; then
  # Install for Linux
  $ECHO "OS: $OS_FULL"
  CHKCONFIG=`which chkconfig`
  copy_init $SCRIPT_NAME 1
  check_group_dba $ORACLE_GROUP
  $CHOWN root:dba $BOOT_DIR/$SCRIPT_NAME
  $CHMOD 755 $BOOT_DIR/$SCRIPT_NAME
  $CHKCONFIG --add $SCRIPT_NAME>/dev/null 2>&1
  $CHKCONFIG --level 345 $SCRIPT_NAME on>/dev/null 2>&1
  # Verify installation
  verify_svc $SCRIPT_NAME
  # Enabling autostart in oratab
  oratab_autostart_enable
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete. Check $SCRIPT_NAME working and if true,"
  $ECHO "restart host to verify."
 else
  $ECHO "ERROR: Unsupported OS: $OS_FULL"
  $ECHO "Exiting..."
  exit 1
 fi
fi

exit 0
