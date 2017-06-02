#!/usr/bin/env bash
# Version: 0.3
# Description: calculate Westpac RKW sending delay
# Author: Claudiu Tomescu
# E-mail: c.tomescu@oberthur.com
# Any suggestions are welcome, especially regarding the calculation of times at midnight,
# see below the section dealing with this
# December 2016

# here we test sftp connections and get the dates (and exit script in case of sftp error)
set -e
wp_sftp=$(/home/oberthur/scripts/sftp_con.sh WestPacM4)
set +e
set -e
sgb_sftp=$(/home/oberthur/scripts/sftp_con.sh SGB)
set +e

# first we define needed variables
curr_date=$(TZ='UTC' date '+%b %d')
curr_time=$(TZ='UTC' date +%H:%M)
curr_hour=$(TZ='UTC' date +%H)
curr_min=$(TZ='UTC' date +%M)
# this applies to WestPac M4
wp_emb_date=$(echo "${wp_sftp}" | awk '/Embossing/ {print $6, $7}')
wp_emb_time=$(echo "${wp_sftp}" | awk '/Embossing/ {print $8}')
wp_emb_hour=$(echo "${wp_sftp}" | awk '/Embossing/ {print substr($8,1,2)}')
wp_emb_min=$(echo "${wp_sftp}" | awk '/Embossing/ {print substr($8,4,2)}')
wp_rkw_date=$(echo "${wp_sftp}" | awk '/Out_reports/ {print $6, $7}')
wp_rkw_time=$(echo "${wp_sftp}" | awk '/Out_reports/ {print $8}')
wp_rkw_hour=$(echo "${wp_sftp}" | awk '/Out_reports/ {print substr($8,1,2)}')
wp_rkw_min=$(echo "${wp_sftp}" | awk '/Out_reports/ {print substr($8,4,2)}')
# and here for WestPac St. George
sgb_emb_date=$(echo "${sgb_sftp}" | awk '/Embossing/ {print $6, $7}')
sgb_emb_time=$(echo "${sgb_sftp}" | awk '/Embossing/ {print $8}')
sgb_emb_hour=$(echo "${sgb_sftp}" | awk '/Embossing/ {print substr($8,1,2)}')
sgb_emb_min=$(echo "${sgb_sftp}" | awk '/Embossing/ {print substr($8,4,2)}')
sgb_rkw_date=$(echo "${sgb_sftp}" | awk '/Out_reports/ {print $6, $7}')
sgb_rkw_time=$(echo "${sgb_sftp}" | awk '/Out_reports/ {print $8}')
sgb_rkw_hour=$(echo "${sgb_sftp}" | awk '/Out_reports/ {print substr($8,1,2)}')
sgb_rkw_min=$(echo "${sgb_sftp}" | awk '/Out_reports/ {print substr($8,4,2)}')
# start with a status of OK
wp_stat="OK"
sgb_stat="OK"

# code for M4 here
# embossing arrived before midnight and rkw sent after midnight
if [[ ($wp_emb_date != $wp_rkw_date) && ($curr_date == $wp_rkw_date) ]]
then
        wp_emb_total=$(( 10#$wp_emb_hour * 60 + 10#$wp_emb_min ))
        wp_rkw_total=$(( 24 * 60 + 10#$wp_rkw_min ))
        curr_total=$(( 24 * 60 + 10#$curr_min ))
# new embossing arrived after midnight but rkw still not sent back since before midnight
elif [[ ($wp_emb_date != $wp_rkw_date) && ($curr_date == $wp_emb_date) ]]
then
        wp_emb_total=$(( 24 * 60 + 10#$wp_emb_min ))
        wp_rkw_total=$(( 10#$wp_rkw_hour * 60 + 10#$wp_rkw_min ))
        curr_total=$(( 24 * 60 + 10#$curr_min ))
else
        wp_emb_total=$(( 10#$wp_emb_hour * 60 + 10#$wp_emb_min ))
        wp_rkw_total=$(( 10#$wp_rkw_hour * 60 + 10#$wp_rkw_min ))
        curr_total=$(( 10#$curr_hour * 60 + 10#$curr_min ))
fi
# code for SGB here
# embossing arrived before midnight and rkw sent after midnight
if [[ ($sgb_emb_date != $sgb_rkw_date) && ($curr_date == $sgb_rkw_date) ]]
then
        sgb_emb_total=$(( 10#$sgb_emb_hour * 60 + 10#$sgb_emb_min ))
        sgb_rkw_total=$(( 24 * 60 + 10#$sgb_rkw_min ))
        curr_total=$(( 24 * 60 + 10#$curr_min ))
# new embossing arrived after midnight but rkw still not sent back since before midnight
elif [[ ($sgb_emb_date != $sgb_rkw_date) && ($curr_date == $sgb_emb_date) ]]
then
        sgb_emb_total=$(( 24 * 60 + 10#$sgb_emb_min ))
        sgb_rkw_total=$(( 10#$sgb_rkw_hour * 60 + 10#$sgb_rkw_min ))
        curr_total=$(( 24 * 60 + 10#$curr_min ))
else
        sgb_emb_total=$(( 10#$sgb_emb_hour * 60 + 10#$sgb_emb_min ))
        sgb_rkw_total=$(( 10#$sgb_rkw_hour * 60 + 10#$sgb_rkw_min ))
        curr_total=$(( 10#$curr_hour * 60 + 10#$curr_min ))
fi

# if we received an embossing file and sent back the RKW, the difference we calculate is the one between RKW sending time and
# when embossing arrived; this is the delay
if [[ "$((10#$wp_emb_total))" -lt "$((10#$wp_rkw_total))" ]]
then
    wp_diff=$(( $wp_rkw_total - $wp_emb_total ))
    # we also need to chek if more than 40 minutes passed since last Embossing file was received
    if [[ $(( $curr_total - $wp_rkw_total)) -gt 30 ]]
    then
        wp_stat="ATTN"
    fi
# if we received an embossing file and the RKW file wasn't sent back yet, the difference we calculate is the one between
# current hour and the one when embossing arrived; this is the waiting time
else
    wp_diff=$(( $curr_total - $wp_emb_total ))
fi
# if any of the above differences (in minutes), either waiting time or time taken to send the RKW file to Westpac is
# greater than 15 mins, the status is KO
if [[ "$((10#$wp_diff))" -gt "15" ]]
then
    wp_stat="KO"
fi
# same logic as above this time for St. George
if [[ "$((10#$sgb_emb_total))" -lt "$((10#$sgb_rkw_total))" ]]
then
    sgb_diff=$(( $sgb_rkw_total - $sgb_emb_total ))
    # we also need to chek if more than 40 minutes passed since last Embossing file was received
    if [[ $(( $curr_total - $sgb_rkw_total)) -gt 40 ]]
    then
        sgb_stat="ATTN"
    fi
else
    sgb_diff=$(( $curr_total - $sgb_emb_total ))
fi
if [[ "$((10#$sgb_diff))" -gt "15" ]]
then
    sgb_stat="KO"
fi

# we write the status files to be used later by PHP
echo "Embossing file:" $wp_emb_time "GMT | Out reports:" $wp_rkw_time "GMT" > /home/oberthur/scripts/wp_status
echo "Embossing file:" $sgb_emb_time "GMT | Out reports:" $sgb_rkw_time "GMT" > /home/oberthur/scripts/sgb_status

today=$(date -u +%Y-%m-%d)

# below we append a line to a history file (where we keep track of delays for RKW sending for M4) only when we are not in waiting state
if [[ "$((10#$wp_rkw_total))" -gt "$((10#$wp_emb_total))" ]]
then
    echo "$today | $(cat /home/oberthur/scripts/wp_status) | $wp_stat | Delay: $wp_diff mins" >> /home/oberthur/scripts/wp_status_history
fi

# we are removing duplicate lines from the history file (it will have a new line added every minute when script is running from cron
# -> many duplicate lines) and we remove lines with no date for RKW and Embossing files, it happens sometimes
awk '!x[$0]++ {if ($3=="Embossing") print $0}' /home/oberthur/scripts/wp_status_history > /home/oberthur/scripts/wp_status_history.tmp \
&& mv /home/oberthur/scripts/wp_status_history.tmp /home/oberthur/scripts/wp_status_history

# we remove some more duplicates here, namely the duplicate lines where RKW appears 2 times, once when it arrives in the Out reports
# folder and then when it's moved from it
tac /home/oberthur/scripts/wp_status_history | uniq -s 10 -w 34 > /home/oberthur/scripts/wp_status_history.tmp
tac /home/oberthur/scripts/wp_status_history.tmp > /home/oberthur/scripts/wp_status_history

# we append the status to the files we read with php and change color of webpage when Westpac is KO
echo "${wp_stat}" >> /home/oberthur/scripts/wp_status
echo "${sgb_stat}" >> /home/oberthur/scripts/sgb_status

# we cp the status files to apache document folder and change owner
sudo cp /home/oberthur/scripts/wp_status /var/www/html/wp_status
sudo chown www-data:www-data /var/www/html/wp_status
sudo cp /home/oberthur/scripts/sgb_status /var/www/html/sgb_status
sudo chown www-data:www-data /var/www/html/sgb_status

# write last RKW and Embosing files time in /tmp files
echo $wp_emb_time $wp_rkw_time > /tmp/westpac_m4
echo $sgb_emb_time $sgb_rkw_time > /tmp/westpac_sgb

exit 0
