#!/bin/bash

BASE_URL="http://prepaid.desco.org.bd/api/tkdes/customer/getBalance"

ACCOUNT=""
METER=""
THRESHOLD=0

while getopts ":a:m:t:h" opt; do
	case "$opt" in
		a)
			if [[ ! "$OPTARG" =~ ^[0-9]+$ ]]; then
				echo "error: invalid argument used with -a" >> /dev/stderr
				exit 1
			fi
			ACCOUNT="$OPTARG"
			;;
		m)
			if [[ ! "$OPTARG" =~ ^[0-9]+$ ]]; then
				echo "error: invalid argument used with -m" >> /dev/stderr
				exit 1
			fi
			METER="$OPTARG"
			;;
		t)
			if [[ ! "$OPTARG" =~ ^[0-9]+$ ]]; then
				echo "error: invalid argument used with -t" >> /dev/stderr
				exit 1
			fi
			THRESHOLD="$OPTARG"
			;;
		h)
			cat <<- EOF
			Usage: $(basename "$0") [OPTIONS]

			Check the balance of a Prepaid DESCO meter. Notify if the balance is
			too low (below specified threshold) and needs to be recharged.

			OPTIONS

			  -a <account-no>
			      Query the balance using DESCO account number.

			  -m <meter-no>
			      Query the balance using DESCO prepaid meter number.

			  -t <threshold>
			      Threshold of remaining balance before sending a notification. (default: 0)

			  -h
			      Print this help information and quit.
			EOF
			exit 0
			;;
		\?)
			echo "error: invalid option -$OPTARG, use -h for help" >> /dev/stderr
			exit 1
			;;
		:)
			echo "error: option -$OPTARG requires an argument" >> /dev/stderr
			exit 1
	esac
done

if [ -z "$ACCOUNT" ] && [ -z "$METER" ]; then
	echo "error: account no or meter no must be specified" >> /dev/stderr
	exit 1
fi

req="${BASE_URL}?accountNo=${ACCOUNT}&meterNo=${METER}" 
resp="$(curl --show-error --silent "$req")"

code="$(echo "$resp" | jq ."code")"
if [[ ! $code =~ ^2[0-9]{2}$ ]]; then
	echo "error: http request failed with code $code" >> /dev/stderr
	exit 1
fi

balance="$(echo "$resp" | jq ".data.balance")"
balance="${balance%.*}"
reading_time="$(echo "$resp" | jq ".data.readingTime")"

if (( balance < THRESHOLD )); then
	notify-send \
		-i appointment-soon \
		-u critical \
		"Recharge DESCO Electric Meter" \
		"Balance is very low: $balance BDT.\nLast checked: $reading_time."
fi

