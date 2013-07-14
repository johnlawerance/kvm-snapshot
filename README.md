kvm-snapshot
============
Released under the WTFPL: WTFPL.txt

kvm-snapshot is a quick and dirty script I wrote for backing up raw .img backups of running KVM guests.

I have only tested and used this script on RHEL6 but I can't imagine any reason it wouldn't run find on other OSes.

In a production environment you should definitely be running KVM guests in LVM vols (preferably on a SAN) in which case this script wouldn't be necessary but I find this approach to be good enough for my own KVM servers.

## Limitations
1. This script suspends (pauses) guests while backups are being performed. KVM snapshots are quick but do note that the VM will be inaccessible during this period. Again in a production environment you should be using LVM snapshotting for your backups or have multiple nodes with a load balancer to prevent downtime.

2. This script does not (currently) write to a log file. I personally have this kicked off by JobScheduler which serves as my logging history. A simple logging function would be trivial to add.

## Dependencies
* libvirt utilities (virsh, virt-clone, etc)
* lbzip2 (for multithreaded bzip2 compression)
