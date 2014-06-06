#!/bin/sh

# Add the following line to snmpd
#
# extend green_temp1 /bin/sh /usr/local/bin/valuegrep.sh Temp1
# extend green_temp2 /bin/sh /usr/local/bin/valuegrep.sh Temp2
# extend green_temp3 /bin/sh /usr/local/bin/valuegrep.sh Temp3
# extend green_humidity /bin/sh /usr/local/bin/valuegrep.sh Humidity
# extend green_humiditytemp /bin/sh /usr/local/bin/valuegrep.sh HumidityTemp
#
#

PATTERN=$1
VALUE=`egrep "\b${PATTERN}\b" /dev/shm/greenhouse.info | cut -d':' -f2` 

echo $VALUE
exit 
