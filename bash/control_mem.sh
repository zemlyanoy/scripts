#!/bin/bash

### Write by Maxim Zemlyanoy 
### 09.20.17

User=$(ls -l $0 | awk '{print $3}')
Group=$(ls -l $0 | awk '{print $4}')
MemTotal=`cat /proc/meminfo | grep MemTotal | head -n1 | awk '{print $2}'`
ActiveUsed=`cat /proc/meminfo | grep Active | head -n1 | awk '{print $2}'`
MemTotalMB=$[$MemTotal / 1024]
ActiveUsedMB=$[$ActiveUsed / 1024]
FreeMemory=$[$MemTotal - $ActiveUsed]
FreeMemoryMB=$[$MemTotalMB - $ActiveUsedMB]
Date=`date '+%m.%d.%y %H:%M:%S'`
Log=/var/log/memory.log

MemAsPercentage () {
UsedPecentage=$[$ActiveUsed * 100 / $MemTotal]
FreePercentage=$[$FreeMemory * 100 / $MemTotal]
}

LogTemplate () {
MemAsPercentage

     echo "#######################################"
     echo "Hostname           : `hostname`"   
     echo "Date               : $Date"
     echo "#######################################" 
     echo "Memory Total (MB)  : $MemTotalMB" 
     echo "Used Memory (MB)   : $ActiveUsedMB"
     echo "Free Memory (MB)   : $FreeMemoryMB" 
     echo "Used Percentage    : $UsedPecentage %"  
     echo "Status             : $State" 
     echo "#######################################" 

}

ControlMem () {
MemAsPercentage

 if [ "$FreePercentage" -ge "60" ]; then
    State="Normal"
    echo $State
    LogTemplate >> $Log
      elif [ "$FreePercentage" -le "37" ]; then
        State="Critical"
        LogTemplate >> $Log
        AppMem=$(ps axo rss,comm,pid | awk '{ proc_list[$2] += $1; } END { for (proc in proc_list) { printf("%d\t%s\n", proc_list[proc],proc); }}' | sort -n | tail -n 1 | awk '{$1/=1024;printf "%.0fMB used ",$1}{print $2 " application"}')
        echo "$AppMem" >> $Log
        /usr/bin/supervisorctl restart all #make sure that your user have enough permissions to run this command
         else 
        State="Idle"
        echo $State > /dev/null
     fi
}

if ! [ -f "$Log" ]; then
##create file if it's doesn't exits with permissions 
sudo touch $Log && sudo chown $User:$Group $Log 
  else 
 ##if file exits 
 ControlMem
fi