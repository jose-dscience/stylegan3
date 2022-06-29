#!/bin/bash

#Default value of argument
BODY="empty body"

for arg in "$@"
do
	case $arg in 
		-body=*)
		BODY="${arg#*=}"
		shift # Remove argument name from processing
        	shift # Remove argument value from processing
        	;;
        	*)
        	OTHER_ARGUMENTS+=("$1")
        	shift # Remove generic argument from processing
        	;;
	esac
done

echo "To: fernandez.fisica@gmail.com" > mail.txt
echo "Subject: Slurm job notification." >> mail.txt
echo "From: jfernand@sissa.it" >> mail.txt
echo $BODY >> mail.txt

sendmail -vt < ./mail.txt
rm ./mail.txt
