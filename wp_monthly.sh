#!/usr/bin/env bash
# Author: Claudiu Tomescu
# E-mail: c.tomescu@oberthur.com
# August 2015

# we declare the last month for which we perform the report
lastMonth=`date --date='-1 month' +%m`
lastMonthName=`date --date='-1 month' +%B`
currentYear=`date +%Y`

# here we search in the main file for all lines from last month, calculate the average, min and max times and write the results in a different file with a custom name
awk 'BEGIN{min=999} /^'"${currentYear}"'-'"${lastMonth}"'/ {avg+=$16; numLines+=1; if ($16>max) max=$16; if ($16<min) min=$16; print $0} END {if (NR>0) printf "%s\n%.2f %s\n%s\n%s %s\n%s\n%s %s\n", "Average time:", avg/numLines, "mins", "Maximum time:", max, "mins", "Minimum time:", min, "mins"}' /home/oberthur/scripts/wp_status_history > /home/oberthur/scripts/westpac/RKW_${lastMonthName}${currentYear}

# if we find "KO" during the last month, append to end of last month status file the lines when we had issues
lastFile="/home/oberthur/scripts/westpac/RKW_${lastMonthName}${currentYear}"
if [ "$(grep KO $lastFile)" ]; then
        ko=$(awk 'BEGIN{print "Westpac KO:"} /KO/ {print $0}' $lastFile);
        echo "$ko" >> $lastFile;
fi

# and finally we delete all lines from initial file containing records from last month
sed -i "/^$currentYear-$lastMonth/d" /home/oberthur/scripts/wp_status_history

#awk 'BEGIN{min=999} /^'"${currentYear}"'-'"${lastMonth}"'/ {avg+=$16; numLines+=1; if ($16>max) max=$16; maxLine=$1; if ($16<min) min=$16; minLine=$1; print $0} END {if (NR>0) printf "%s\n%.2f %s\n%s\n%s %s %s\n%s\n%s %s %s\n", "Average time:", avg/numLines, "mins", "Maximum time:", max, "mins on", maxLine, "Minimum time:", min, "mins on", minLine}' /home/oberthur/scripts/wp_status_history > /home/oberthur/scripts/westpac/RKW_${lastMonthName}${currentYear}

exit
