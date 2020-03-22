#!/bin/bash

LOG=$1
COUNT=11  #TOP ip adresses with arp requests
IP_REGX='([[:digit:]]{1,3}\.+){3}([[:digit:]]){1,3}'


events_counter () {
	head -$1 $attacker | tail -n1 | read -r -a numb
	if [ "${numb[0]}" -gt 10 ]; then
		ALL_MIN=
		minute=$(echo "${numb[1]}" | grep --only-matching --extended-regexp '[0-9]{2}T[0-9]{2}:[0-9]{2}')
		grep -E $minute $attacker > min.tmp
		while read -r -a amount; do
			(( ALL_MIN += ${amount[0]} ))
		done < min.tmp
		echo -e "\tHOST $(basename $attacker) made $ALL_MIN arp requests at $minute"
		#sed -n -i "s/${minute}/" "/g" $attacker #Delete used minutes
	fi

}

mkdir ./find
#Get source ip and timestamp
#OR MAYBE MAC ADDRESS?
cut --fields=2,3 --delimiter=, $LOG > ./temp_log.tmp
#Sort ip repeats
#OR MAYBE TIME SEQUNCE?
grep --only-matching --extended-regexp $IP_REGX ./temp_log.tmp | sort | uniq --count --repeated | sort --key=1nr > ./result_ip.tmp

#Counter sorting requests in one second
for (( i=1; i<COUNT; i=i+1 )); do
	ip=$(sed --silent "${i}p" ./result_ip.tmp | grep --only-matching --extended-regexp $IP_REGX)
	grep --extended-regexp "${ip}\"" ./temp_log.tmp | cut --fields=1 --delimiter=, > ./time_$ip.tmp
	grep --only-matching --extended-regexp '[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' ./time_$ip.tmp | sort \
| uniq --count --repeated | sort --key=1nr > ./find/$ip
done

set +m  #Enable monitor mode for lastpipe
shopt -s lastpipe  #Disable subshell for save var
#Events is one minute
for attacker in ./find/*; do
	events_counter 1
	events_counter 2
	events_counter 3
done
set -m

rm --recursive --force ./find/ ./*.tmp
