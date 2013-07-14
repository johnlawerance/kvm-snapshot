#!/bin/bash
#
# KVM-Snapshot
# http://github.com/johnlawerance
# http://johnlawerance.com
# 
# Released under the WTFPL (http://www.wtfpl.net/)
# See WTFPL.txt for the full license legalese
#
#TODO: Logging, encryption option, list dependencies

# If set to 1 compression (bzip2) enabled
ENABLE_COMPRESSION="1"

# Space separated list of VMs that you DO NOT want to be backed up.
EXCLUDED_VMS="test-1"

# Location backups will be stored. This should be an NFS vol, or iSCSI target or something remote.
BACKUP_DIR="/backups"

# Retention (in days) of backups to keep
VM_RETENTION="5"

DATE=`date +%F`
BZIP=/usr/bin/lbzip2

set -e
# Make sure only root can run the script
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# Get full list of VMs
VMS=`virsh list|sed -n '1!p'|awk {'print $2'}`

# Remove excluded VMS from list
for EXCLUDE in $EXCLUDED_VMS
do
	VMS=`echo $VMS| sed "s/\b$EXCLUDE\b//g"`
done


# Cycle through list of VMs (sans excluded) and pause, snapshot, transfer, compress, and resume.
for BACKUP_VM in $VMS
do
	echo "Staring backup for: $BACKUP_VM"
	mkdir -p $BACKUP_DIR/$BACKUP_VM/$DATE
	echo "Suspending $BACKUP_VM"
	virsh suspend $BACKUP_VM
	virt-clone --original $BACKUP_VM --auto-clone --file $BACKUP_DIR/$BACKUP_VM/$DATE/$BACKUP_VM.img
	virsh dumpxml $BACKUP_VM-clone > $BACKUP_DIR/$BACKUP_VM/$DATE/$BACKUP_VM.xml
	virsh undefine $BACKUP_VM-clone
	virsh resume $BACKUP_VM
	if [ "$COMPRESSION" -eq "1" ]
		echo "Compressing $BACKUP_VM backup"
		tar -cf $BACKUP_DIR/$BACKUP_VM/$DATE.tar $BACKUP_DIR/$BACKUP_VM/$DATE
		$BZIP $BACKUP_DIR/$BACKUP_VM/$DATE.tar
		rm -Rf $BACKUP_DIR/$BACKUP_VM/$DATE
	fi
	echo "Searching and deleting old backups per retention: $VM_RETENTION days"
	find /$BACKUP_DIR/$BACKUP_VM/* -mtime +$VM_RETENTION -exec rm {} \;
done

