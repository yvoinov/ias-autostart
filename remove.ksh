#!/bin/ksh

# Oracle iAS autostart remove for Solaris 8,9,10,>10, Linux
# Yuri Voinov (C) 2006-2010
#
# ident "@(#)remove.ksh    2.5   10/11/01 YV"
#

#############
# Variables #
#############

# Installation files list
F1="infra.xml"
F2="midtier.xml"
F3="midtier_local.xml"
F4="init.ias_infra"
F5="init.ias_midtier"
F6="inst_infra.sh"
F7="inst_midtier.sh"
F8="rm_infra.sh"
F9="rm_midtier.sh"
F10="inst_wcache.sh"
F11="init.ias_wcache"
F12="wcache.xml"
F13="rm_wcache.sh"
F14="rm_infra.conf"

# Supported OS list 
SUPPORTED_OS="Solaris: 8,9,10,>10; Linux: RHEL3/4/5,SuSE,Fedora,OEL"

# Copyright string
COPYRIGHT="Yuri Voinov (C) 2006, 2010"

# Boot dir variable. Uses for check installed service
BOOT_DIR="/etc/init.d"

# Select prompt
PS3='Choose iAS installation type to remove autostart: '

#  
# OS Commands location variables
#
CLEAR=`which clear`
ECHO=`which echo`

################
# Subroutines. #
################

# Check all critical files
check_all ()
{
 if [ ! -f $F1 -o ! -f $F2 -o ! -f $F3 -o ! -f $F4 -o ! -f $F5 \
      -o ! -f $F6 -o ! -f $F7 -o ! -f $F8 -o ! -f $F9 -o ! -f $F10 \
      -o ! -f $F11 -o ! -f $F12 -o ! -f $F13 -o ! -f $F14 ]; then
  $ECHO "ERROR: Not at all required files exists."
  $ECHO "       Uncompress archive and try again."
  exit 1
 fi
}

# Check infrastructure autostart installed
check_infra_installed ()
{
 if [ ! -f $BOOT_DIR/$F4 ]; then
  $ECHO "ERROR: Infrastructure autostart already removed."
  exit 1
 fi
}

# Check infrastructure autostart installed
check_midtier_installed ()
{
 if [ ! -f $BOOT_DIR/$F5 ]; then
  $ECHO "ERROR: Middle tier autostart already removed."
  exit 1
 fi
}

# Check webcache autostart installed 
check_wcache_installed ()
{
 if [ ! -f $BOOT_DIR/$F11 ]; then
  $ECHO "ERROR: WebCache autostart already removed."
  exit 1
 fi
}

# Choice installation type to remove autostart
choice_of()
{
select inst_type
do
 case $inst_type in
  "Single host")
   $CLEAR
   $ECHO "*** Single host installation"
   check_infra_installed
   ./rm_infra.sh
   $ECHO "*** Infrastructure autostart removal complete."
   $ECHO "*** Press <Enter> to continue, <Crtl+C> to cancel..."
   read p
   $CLEAR
   check_midtier_installed
   ./rm_midtier.sh
   $ECHO "*** Middle tier autostart removal complete."
   $ECHO "*** Press <Enter> to exit..."
   read p
  ;;
  "Infrastructure")
   $CLEAR
   $ECHO "*** Infrastructure only installation"
   check_infra_installed
   ./rm_infra.sh
   $ECHO "*** Infrastructure autostart removal complete."
   $ECHO "*** Press <Enter> to exit..."
   read p
  ;;
  "Middle tier")
   $CLEAR
   $ECHO "*** Mddle tier only installation"
   check_midtier_installed
   ./rm_midtier.sh
   $ECHO "*** Middle tier autostart removal complete."
   $ECHO "*** Press <Enter> to exit..."
   read p
  ;;
  "Standalone WebCache")
   $CLEAR
   $ECHO "*** Standalone WebCache installation"
   check_wcache_installed
   ./rm_wcache.sh
   $ECHO "*** WebCache autostart removal complete."
   $ECHO "*** Press <Enter> to exit..."
   read p
  ;;
  "Exit")
   $ECHO "Nothing to do"
   exit 1
  ;;
  *)
   $ECHO "*** What?"
   exit 1
 esac
 break
done
}

##############
# Main block #
##############

$CLEAR

# Check consistancy of installation
check_all

$ECHO "-------------------------------------------"
$ECHO "iAS UNIX autostart remove"
$ECHO ""
$ECHO "Supported OS:"
$ECHO "$SUPPORTED_OS"
$ECHO ""
$ECHO "$COPYRIGHT"
$ECHO "-------------------------------------------"
$ECHO ""
$ECHO "iAS Installation type"
$ECHO ""

choice_of "Single host" "Infrastructure" "Middle tier" "Standalone WebCache" "Exit"

exit 0
