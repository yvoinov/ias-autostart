# Oracle iAS Autostart
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://github.com/yvoinov/ias-autostart/blob/master/LICENSE)

                      ***************
                      * Version 2.5 *
                      ***************

This set of scripts allows you to activate and disable automatic start  and  stop  of  services  Oracle iAS (Infrastructure, Middle Tier, Standalone WebCache) and all its derivatives in one step on the following systems:

- Solaris 8,9
- Solaris 10 and above
- Linux (RHEL3/4/5, SuSE, Fedora, Oracle Enterprise Linux)

To perform autostart of Oracle services, a set is used scripts init.ias_infra, init.ias_midtier, init.ias_wcache. Depending on the platform (Solaris 8-10 and above, or Linux), either links are created in the /etc/rc3.d directory, or the service is registered and created links with the chkconfig command (Linux), or registering the service(s) with the SMF service. 

Platform recognition is done automatically. Autostart can be done for iAS infrastructure and middle tier iAS installed either on one machine or on two (enterprise installation) (including with configuring OHS/WebCache to use port 80 or SSL). Autorun is also supported for iAS Standalone WebCache installation. For autostart installation use main install.ksh script or (if you need) individual installation scripts inst_*.sh. Before installation you must check and edit config variables in \*.conf files.

To install script(s) and/or create links and registering descriptors for autorun services, install.ksh script is used or (if necessary) step-by-step (step-by-step or machine-by-machine) activation possible autorun using inst_\*.sh scripts. 

Before starting the installation, check and edit the \*.conf configuration file variables depending on the service configuration of the target host(s). Of course, installation and removal scripts install.ksh/remove.ksh/inst_*.sh/rm_\*.sh should run from the root account.

## ASM

iAS components must be launched in a specific sequences.

When  starting  iAS, the infrastructure should start first - RDBMS, listener, OIS, SSO, OHS, iasconsole in sequence:

1. Listener
2. ASM
3. RDBMS
4. OPMN
5. OID
6. SSO
7. OHS
8. iasconsole (optional)
9. (when using iAS 10R2 and above) dbconsole

Only after the infrastructure is launched should middle be started tier and (if any) stand-alone WebCache.\*

The middle tier also starts in a certain sequence:

1. OPMN (including middle tier components)
2. iasconsole

\* Standalone WebCache does not need for its correct launch in the need to launch the infrastructure, although it may be registered with it.

When using OCS (Oracle Collaboration Suite), it is also necessary to additionally start on the middle tier TNS listener (for IMAP).

In this case, the middle tier should not start until the infrastructure will not start (because it requires registration of middle tier services in OID), regardless of In addition, local infrastructure is being launched, or remote.

When launching Standalone WebCache, sometimes it is also necessary to start iasconsole, which is installed with it.

To provide the necessary startup logic, startup scripts written accordingly. Infrastructure is starting without additional checks, the process is automatic launching the middle tier after the start of the host periodically checks if the infrastructure has started. Checks performed as in a single-machine installation (all iAS components are installed on a single host) and enterprise installation (components installed on at least two machines - infrastructure and middle tier).

In this case, these checks are not performed indefinitely. If during a certain timeout the starting middle tier could not see the running infrastructure, the subsequent the start of middle tier processes is not performed in the journal the corresponding entry is made in the file.

As recommended by enterprise installation, iAS can be configured with multiple middle tiers, all they will start only after the launch of the central infrastructure.

Autoshutdown of iAS services during hosts shutdown is performed without additional checks, but also in compliance with the correct iAS process stop sequences (in order, reverse start order).

## Configuring the Infrastructure to start automatically

For  infrastructure,  edit  as  needed  ias_infra.conf  file variables:

```
#
# oratab location. 
# Leave variable blank to use /var/opt/oracle/oratab
#
ORATAB=""
^^^^^^^^^ On some platforms it is necessary to set explicitly, if oratab is not present in standard locations (/var/opt/oracle/oratab or /etc/oratab). Write absolute path and filename of oratab (not necessarily oratab, but standard structure).

IMPORTANT - Auto start flag in oratab file changes explicitly when installing and removing the service - set to Y if infrastructure autostart service activated and set to N during uninstallation automatic launch of the infrastructure.

#
# ORACLE_SID and ORACLE_HOME variables.
# Leave variables blank to use oratab
#
ORACLE_SID=""
ORACLE_HOME=""
^^^^^^^^^^^^^ If the parameters are set explicitly, to run RDBMS/Listener will be used by them, not the content oratab (taken in standard places or explicitly given in the previous setting).

#
# Startup/shutdown privilege for "connect as" to RDBMS
# instance(s).
# By default is "sysdba".
#
#ORACLE_DB_PRIV="sysoper"
ORACLE_DB_PRIV="sysdba"
^^^^^^^^^^^^^^^^^^^^^^^ A system privilege that allows start/stop Oracle. By default sysdba. It may differ on your system (set during Oracle installation).

#
# Startup/shutdown privilege for "connect as" to ASM
# instance(s).
# By default is "sysdba" (Oracle 10),
# set to "sysasm" for Oracle 11 and above.
#
#ORACLE_ASM_PRIV="sysasm"
ORACLE_ASM_PRIV="sysdba"
^^^^^^^^^^^^^^^^^^^^^^^^^ Start/Stop Privilege for ASM instances. In Oracle 10 - sysdba since Oracle 11 - sysasm. By default sysdba.

#
# ASM shutdown mode. In some cases (not patched DB etc.) ASM
# instance cannot shutdown in immediate mode after correctly
# shutdown main DB and must be stopped # in shutdown abort
# mode.
#
# Beware, that this stop mode can damage your ASM diskgroups!
#
#ASM_SHUTDOWN_MODE="abort"
ASM_SHUTDOWN_MODE="immediate"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ASM service stop mode. In some cases, after the correct shutdown of the main database services ASM services cannot be stopped in immediate mode (not installed patches, etc.). For such situations, it is planned to stop ASM instances in abortion mode. Please note that this ASM termination may lead to disk group corruption and is not recommended unless emergency.

#
# If configured OEM iasconsole, set USEIASCTL to 1. 
# Leave blank if not.
# Default value: 1
USEIASCTL="1"
^^^^^^^^^^ For iAS, the console is always configured within installation procedures. If you need to run it in as part of the autorun procedure, the parameter must be set. When accessing the system from the Internet, iasconsole must be pre-configured to work under SSL (for example, emctl secure iasconsole command). In some very rare cases of automatic launch of the console control cannot be executed and must be run manually.

#
# If configured OEM dbconsole, set USEDBCTL to 1. 
# Leave blank if not.
# Default value: none
# Note: dbconsole supported only from Oracle10g(>iAS 10g R2)
USEDBCTL=""
^^^^^^^^^^^ OEM dbconsole is used when using iAS > 10g R2 (it includes RDBMS 10g). Default it is assumed that iAS R1 is used and, accordingly, this parameter is not set. If required automatically run dbconsole (when using iAS R2 and higher, which include the Oracle10g DBMS), you must specify this parameter is set to 1.

#
# If configured OCA (Certified Authority), set USEOCA to 1. 
# Leave blank if not.
# Default value: none
# Note: OCA required additional ocactl start/stop command 
# on some iAS'es
USEOCA=""
^^^^^^^^^ The parameter is set if it is necessary to execute start OCA (ocactl start). It should be taken into account that when When configuring the OCA, the root password is set and should be enter at startup. For this reason, the value of the parameter The default is "empty" (OCA is not started. In this case, OC4J service OCA starts anyway within the start processes infrastructure).

#
# Log file. Default /var/adm/oracle.log
#
LOG="/var/log/oracle.log"
^^^^^^^^^^^^^^^^^ Path and name of the default log file. If a file does not exist (say regularly serviced cron process) then it will be created when executing init.ias_infra .
```

## Configuring the middle tier to start automatically

For the middle tier, the following file variables are edited with ias_midtier.conf:

```
#
# ORA_HOME variable for middle tier.
# This is substitution variable for legal
# ORACLE_HOME variable below. 
# DO NOT RENAME THIS VARIABLE!!
ORA_HOME="/export/home/OraHome2"
^^^^^^^^ The ORACLE_HOME home directory for the middle tier. Must be specified anyway, since the entry oratab for middle tier may be missing, just like and oratab. DO NOT RENAME THIS VARIABLE!

#
# If configured OEM iasconsole, set USEIASCTL to 1. 
# Leave blank if not.
# Default value: 1
USEIASCTL="1"
^^^^^^^^^^ For iAS, the console is always configured within installation procedures. If you need to run it in as part of the autorun procedure, the parameter must be set. When accessing the system from the Internet, iasconsole must be pre-configured to work under SSL (for example, emctl secure
iasconsole command). In some very rare cases of automatic launch of the console control cannot be executed and must be run manually.

#
# If installation type is OCS with IMAP, set USETNS to 1. 
# Leave blank if not.
# Default value: null (empty string)
USETNS=""
^^^^^^^^^ If automatic start of the middle tier is needed OCS and IMAP configuration is done, you need to set parameter set to 1 to start TNS listener. In the rest cases are not specified.

#
# Infrastructure hostname or IP address.
# Must contains remote infrastructure hostname 
# (required entry in /etc/hosts) or IP-address. 
# If IP/hostname for infrastructure node changed,
# must be changed too. 
# Default is local hostname ("``hostname").
#
IHOST="`hostname`"
^^^^^^ Infrastructure host name or IP address. (We can not automatically find where the OID is). Default set to "`hostname`" for a single machine installation, or you need to set the name of the infrastructure remote host (in this case the /etc/hosts file should contain an appropriate entry, otherwise you can set the IP address of the infrastructure).

#
# OID port. Default 3060 (iAS 9.0.4),
# 389 for iAS 10.1.x - Non SSL,
# if SSL - default 3131 for iAS 9.0.4, 636 for iAS 10.1.x.
# 
# Check after installation on insfastructure iasconsole 
# ports tab before edit.
#
OID_PORT=389
^^^^^^^^ Infrastructure OID port number. Default 389 (standard LDAP port) if the OID is configured with using SSL, the default value is 636 (for iAS > 10g R1). For iAS 9.0.4, the default values are 3060 for Non SSL, and 3131 for the OID SSL port. Port used to check if the infrastructure is running. Port may have a different meaning. The assigned port numbers can be look either in a file (UNIX) ORACLE_HOME/install/portlist.ini or in the management console installed iAS (tab Farm-><iAS Instance>->Ports).

#
# ONS (OPMN) Request. Default 6004.
# Check after installation on insfastructure iasconsole
# ports tab before edit.
# Default values: 6004 for single host installation,
# 6003 for enterprise installation.
ONS_REQ=6004
^^^^^^^ ONS port number (OPMN) Request middle tier. Meaning the default depends on the installation type. For installation on one host, the default value is 6004, for enterprise installations - 6003. The port is used to check if the middle tier services are running. The port may be different. Assigned Port Numbers can be viewed either in a file (UNIX) ORACLE_HOME/install/portlist.ini or in the management console installed iAS (tab Farm-><iAS Instance>->Ports).
Note: In some iAS installations on the same host the infrastructure can start the ONS_REQ service on port 6003.

#
# ONS (OPMN) Remote. Default 6201.
# Check after installation on insfastructure iasconsole
# ports tab before edit.
# Default values: 6201 for single host installation,
# 6200 for enterprise installation.
ONS_REM=6201
^^^^^^^ Port number ONS (OPMN) Remote middle tier. Meaning the default depends on the installation type. For installation on one host, the default value is 6201, for enterprise installations - 6200. The port is used to check if the middle tier services are running. The port may be different. Assigned Port Numbers can be viewed either in a file (UNIX) ORACLE_HOME/install/portlist.ini or in the management console installed iAS (tab Farm-><iAS Instance>->Ports). 
Note: In some iAS installations on the same host the infrastructure can start the ONS_REM service on port 6200.

#
# Grace time. Uses for check infrastructure
# already started. In seconds.
# Recommended value: 15 for single host installation,
# 60 for enterprise installation.
GRACETIME=15
^^^^^^^^^ Time period between attempts to detect a trigger infrastructure in seconds. The default is set to 15 seconds for single machine installation, and 60 seconds for enterprise installations.

#
# Grace time 2. Uses for middle tier
# running check. In seconds.
# Recommended value: 5 for iAS/Portal single host,
# 60 for iAS/Portal enterprise,
# 60 for OCS single host installation,
# 180 for OCS enterprise installation.
GRACETIME2=5
^^^^^^^^^^ Time period between attempts to detect middle tier startup locally. The default time depends on the type installation and, accordingly, the number of launched services (and indirectly depends on the performance of the middle tier host. Than a less powerful machine is used to install the middle tier, the longer the time interval must be set). Default is 5 seconds for a single machine installation iAS/Portal, 60 seconds for iAS/Portal enterprise installation, 60 seconds for a single machine OCS setup, and 180 seconds for an enterprise installation of OCS.

#
# Attempts to connect to infrastructure.
# Recommended value: 10 (150 sec total timeout)
# for single host installation,
# 100 (25 min total timeout)
# for enterprise installation.
CHECK_LIMIT=100
^^^^^^^^^^^ Number of attempts to detect start infrastructure (with GRACETIME interval) and local middle tier (with GRACETIME2 interval). Ultimate infrastructure start detection interval, thus default is 150 seconds for single machine installation, and 1500 seconds (25 minutes) for enterprise-settings, and the start detection limit middle tier will be 50 seconds for single machine installation iAS, and 1500 seconds (25 minutes) for an enterprise installation. If at the end of the detection interval start infrastructure cannot be discovered, startup process middle tier is terminated and the corresponding message will write to $LOG.

When running the local middle tier, this is the same number of times the launch detection is attempted middle tier processes. If middle tier expires period GRACETIME2*CHECK_LIMIT does not start, start middle tier is terminated with the entry of the corresponding messages to $LOG. Then it is launched iasconsole (if USEIASCTL is set), and later, the administrator can start/restart middle tier process processes manually through the management console interface.

#
# Log file. Default /var/adm/oracle.log for Solaris,
# /var/log/oracle.log for Linux
#
LOG="/var/log/oracle.log"
^^^^^^^^^^^^^^^^^ Path and name of the default log file. If a file does not exist (say regularly serviced cron process) then it will be created when executing init.ias_midtier . If the name of the log file matches the name specified in the file ias_infra.conf and iAS is installed on the same host, entries infrastructure start processes and middle tier will be be added to the log file in two consecutive clearly
distinct groups. The administrator can also maintain separate iAS service group start/stop logs.
```

## Configuring WebCache to start automatically

Actually installing Standalone WebCache is not quite correct term. In fact, Oracle uses two webcache installation configurations:

- WebCache + OC4J (from iAS distribution)
- Standalone WebCache.

Strictly speaking, installing Standalone WebCache should take the second option.

The differences lie in a different set of software and services and the different nature of the launch of the WebCache installation processes.

The first type of installation produces the launch of WebCache processes via OPMN and in almost all cases installs and configures iasconsole to manage the installation webcache.

For these reasons, WebCache installations are configured in slightly different ways for different installations.

For this reason WebCache autostart uses two different techniquies for control WebCache.

For Standalone WebCache, the following variables of the ias_wcache.conf file are edited:

```
#
# ORA_HOME variable for Standalone WebCache.
# This is substitution variable for legal
# ORACLE_HOME variable below. 
# DO NOT RENAME THIS VARIABLE!!
ORA_HOME="/export/home/OraHome2"
^^^^^^^^ ORACLE_HOME home directory for Standalone webcache. Must be specified, since the oratab entry for the middle tier may be missing, as well as oratab. DO NOT RENAME THIS VARIABLE!

#
# If WebCache installed from iAS distributive,OPMN used by
# default. Standalone WebCache uses webcachectl.
# Leave blank if use Standalone WebCache.
# Default value: 1
#
USEOPMN="1"
^^^^^^^ The parameter is set when installing WebCache+OC4J, and _is not set_ when installing Standalone WebCache. Since WebCache is usually installed from the iAS distribution, it contains the OPMN and uses the OPMN to start the WebCache processes.

#
# If configured OEM iasconsole, set USEIASCTL to 1. 
# Leave blank if not. Default value: 1
USEIASCTL="1"
^^^^^^^^^^ For iAS, the console is always configured within WebCache+OC4J installation procedures. If you need to run it as part of the autorun procedure, the parameter must be set. When accessing the system from the Internet, iasconsole must be pre-configured to work under SSL (for example, with the emctl secure iasconsole command). In some very rare cases, the management console cannot be automatically started and must be started manually. With Standalone WebCache installations, this parameter is not set (empty string) because the Standalone WebCache installation usually does not contain a console.

#
# Log file. Default /var/adm/wcache.log
#
LOG="/var/log/wcache.log"
^^^^Path and name of the default log file. If the file does not exist (say, regularly maintained by a cron process) then it will be created when init.ias_wcache is executed. Since the launch of WebCache processes is usually not tied to a specific startup sequence of other Oracle services, it is recommended to leave the default value (a log file separate from other logs of automatically started services) when installing on a host not only WebCache services.
```

## Installing and activating automatic start services

To install autorun services, you need to unpack the following files (for each host in case of an enterprise installation or one for a single-machine installation):

```
install.ksh         - main interactive installation script
remove.ksh          - main interactive uninstallation script
init.ias_infra      - main infrastructure autostart control
                      script
init.ias_midtier    - main middle tier autostart control
                      script
init.ias_wcache     - main WebCache autostart control script
infra.xml           - Infrastructure SMF-manifest
midtier.xml         - Middle tier SMF-manifest
midtier_local.xml   - Middle tier local SMF-manifest for
                      single host installation
wcache.xml          - WebCache SMF-manifest
inst_infra.sh       - Infrastructure autostart installation
                      script
inst_midtier.sh     - Middle tier autostart installation
                      script
inst_wcache.sh      - WebCache autostart installation
                      script
rm_infra.sh         - Infrastructure autostart uninstall
                      script
rm_midtier.sh       - Middle tier autostart uninstall
                      script
rm_wcache.sh        - WebCache autostart uninstall script
readme_ru.txt       - Russian readme
readme_en.txt       - This file
webcache_port80.txt - Additional steps for start OHS/WebCache
                      on 80/443 port
ias_infra.conf      - init.ias_infra config file
ias_midtier.conf    - init.ias_midtier config file
ias_wcache.conf     - init.ias_wcache config file
inst_infra.conf     - inst_infra.sh config file
inst_midtier.conf   - inst_midtier.sh config file
inst_wcache.conf    - inst_wcache.sh config file
rm_infra.conf       - rm_infra.sh config file
```

to the required directory and execute with account rights root install.ksh script. The script is executed interactively, to activate the automatic launch of the required set of iAS services, select corresponding menu item. After its completion, all the necessary file structures will be created and you can activate the service either by restarting the host (Solaris 8.9, Linux) or by executing the commands (Solaris 10):
```
# svcadm enable ias_infra
# svcadm enable ias_midtier
# svcadm enable ias_wcache
```
for each of the iAS components, respectively.

The launch of services can be controlled in a separate session:
```
# tail -f /var/log/oracle.log  (Log name and path can be
different)
```
To stop and delete autostart, you need to do following:

- For Solaris 8,9, Linux:
1. Stop iAS services manually
2. Run remove.ksh as root

- For Solaris 10 and above:
1. Run commands:
```
# svcadm disable ias_infra
# svcadm disable ias_midtier
# svcadm disable ias_wcache
```
2. Run remove.ksh as root

The remove.ksh script is also interactive, acting like the install.ksh script. When it is launched, a menu appears in which you must select the target iAS configuration on which automatic launch is deactivated. Before the deactivation is performed, the activation of autorun on this host is checked, if automatic launch is not activated, then, of course, the deletion is not performed. With a single-machine installation (all services are installed on the same host), it is possible to perform a selective removal operation, for example, remove only the automatic launch of the infrastructure or only the middle tier, etc. It is also possible to selectively execute low-level rm_\*.sh removal scripts.

Note: The activation/removal of automatic startup is fairly secure and does not, under any circumstances, affect installed and configured iAS services.

Autostart control scripts can also be executed interactively (eg for debugging purposes).

## Troubleshooting

### Firewalls

When installing all iAS hosts in the DMZ (demilitarized zone), there are no problems with detecting the middle tier of starting services. However, if the existing network topology is complex, or when using IPSec / IPfilter services on hosts or routers, unlimited timeouts are possible when the middle tier autorun service tries to detect the start of a remote infrastructure (installed on another host). In this case, it is necessary to check and, if necessary, change the IPSec/IPfilter settings so that the appropriate ports are
opened on the infra-middle tier route (the names of the ias_midtier.conf configuration parameters for the init.ias_midtier start script are given):
```
OID_PORT (Default 3060 (iAS 9.0.4), 389 for iAS 10.1.x - Non
SSL, if SSL - default 3131 for iAS 9.0.4, 636 for iAS
10.1.x.)
ONS_REQ (Default 6004 for single host installation, 6003 for
enterprise installation.)
ONS_REM (Default 6201 for single host installation, 6200 for
enterprise installation.)
```

### Technical note

Firewalls are usually configured to drop packets outside the allowed ranges/ports, causing the discovery procedure to wait for a response indefinitely, which causes the middle tier startup procedure to get stuck. The existing implementation of the discovery procedure does not keep track of fixed timeouts, which leads to this effect. The only reasonable solution is to properly configure firewalls and service ports.

## Notes

1. To run OHS/WebCache from the root account on the middle tier and Standalone WebCache (when binding ports<1024), after configuring the ports in webcache.xml (or via the administrative console), perform an additional operation (when the WebCache/middle tier services are stopped) from root account name:

```
# cd $ORACLE_HOME/webcache/bin
# ./webcache_setuser.sh setroot <Oracle software owner>
```

2. When autostarting on Solaris 10 and higher, the remote middle tier checks the start of the infrastructure when the service appears on the OID port; in a single-machine installation, the local middle tier first tracks dependencies within the XML descriptor of the service and does not start the middle-tier launch process until the start process is completed infrastructure, after which it checks the health of the OID in the usual way (port scan).

3. When installing automatic launch services on Linux, in some cases, anomalies in the launch of management consoles are possible (Java exceptions, premature partial launch of consoles, etc.). These problems are caused by the management consoles Java code in combination with a symbolic link to the operating system's native Java (/usr/bin/java). In order to eliminate them, you need to make sure that the /usr/bin/java link looks at JRE version 1.4.2 or higher. In case the OS does not contain a JRE of this version or higher, you must either redefine the link to JRE 1.4.2 included with the iAS software, or install the latest JRE from java.com and also change the link:

```
# unlink /usr/bin/java
# ln -sf /usr/bin/java <задать $ORACLE_HOME>/jre/1.4.2/bin

```
or

```
# unlink /usr/bin/java
# ln -sf /usr/bin/java /usr/j2se/jre/bin/java
```

(change paths to your installation in examples above)

4. When using automatic startup services on Oracle Enterprise Linux, in some configurations, a situation may occur when OC4J_SECURITY is not launched on the infrastructure and, accordingly, OSSO is not started. However, the management console starts and, in this case, administrator intervention is required to manually start the OC4J_SECURITY process. After its successful start, the OSSO
service starts automatically. Similarly, blocking of the Discoverer service at the midle tier can occur, which can also be eliminated by manually starting the process through iasconsole. This problem is also eliminated by a full system restart with the command (in particular, the `shutdown -i 6 -y now` command). The specified behavior is not related to the autostart service, but is caused solely by the characteristics of Oracle Enterprise Linux. When using autostart services on other Lunix implementations, the problem usually does not occur.

5. When zoned installation of iAS services on Solaris 10 and above, it is necessary to copy the init.ias_\* startup scripts to the /lib/svc/method directory of the global zone with root:sys _BEFORE START_ services.

In non-global zones, this directory is mounted from the global zone with read only permissions, and the necessary actions to install startup methods in it cannot be correctly performed.
