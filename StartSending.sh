#!/bin/bash 

DEBUG ()
{
	echo "$@"
}

ReadConfigFile () 
{
	export NUM_LINES_PROCESSED=`grep NUM_LINES_PROCESSED $CONFIG_FILE | awk -F"=" '{print $2;}'`
	export EMAILS_PER_ACCOUNT=`grep EMAILS_PER_ACCOUNT $CONFIG_FILE | awk     -F"=" '{print $2;}'`
}

SetDefaultValues ()
{
	export NUM_LINES_PROCESSED=0
	export EMAILS_PER_ACCOUNT=350
	echo "$1 running without $CONFIG_FILE config file"
	echo "Default values : "
	echo "NUM_LINES_PROCESSED=0"
	echo "EMAILS_PER_ACCOUNT=350"
	read -p "Do you want to run script with Default config values?yY/[nN]" ans
	if [ "$ans" != "Y" -a "$ans" != "y" ]
	then
		echo "Exiting script"
		exit;
	fi
}

CheckArguments ()
{
	if [ $# != 2 ]
	then 
		echo "Usage: $0 <EMAIL_LIST_FILE> <CRED_INFO_FILE>"
		exit 2;
	else
		export EMAIL_LIST="$1"
		export CRED_FILE="$2"
	fi

	if [ "$EUID" != "0" ] 
	then
		echo "Run with root privileges"
		exit 1;
	fi
}

WriteToConfigFile ()
{
	if [ ! -d `dirname $CONFIG_FILE` ]
	then
		mkdir `dirname $CONFIG_FILE`
	fi

	echo "NUM_LINES_PROCESSED=$1" > $CONFIG_FILE
	echo "EMAILS_PER_ACCOUNT=$2" >> $CONFIG_FILE
}

CreateListToProcess ()
{
	NUM_ACCOUNTS=`cat $CRED_FILE | wc -l`
	LINES_TO_EXTRACT=$(( NUM_ACCOUNTS * EMAILS_PER_ACCOUNT ))
	START_POS=$(( NUM_LINES_PROCESSED + 1 ))
	END_POS=$(( START_POS + LINES_TO_EXTRACT - 1))
	QUIT_POS=$(( START_POS + LINES_TO_EXTRACT ))
	echo "LINES_TO_EXTRACT=$LINES_TO_EXTRACT"
	echo "START_POS=$START_POS"
	echo "END_POS=$END_POS"
	echo "QUIT_POS=$QUIT_POS"
	if [ ! -d temp ] 
	then
		mkdir temp
	fi
	sed -n "${START_POS},${END_POS}p;${QUIT_POS}q" "${EMAIL_LIST}" > ./temp/$$.temp
	cd temp
	split -a 6 --numeric-suffixes=1 -l ${EMAILS_PER_ACCOUNT} $$.temp $$RUN_
	rm $$.temp
	cd -
	WriteToConfigFile $END_POS $EMAILS_PER_ACCOUNT
}

LoadAccountsAndSendMail ()
{
	line=`echo $1 | awk -F"RUN_" '{print $2;}'`
	credentials=`sed -n "${line}p" $CRED_FILE`
	file_name=$1
	smtp=`echo $credentials | awk '{print $1;}' | sed 's/\[//' | sed 's/\]//'`
	username=`echo $credentials | awk '{print $2;}' | awk -F":" '{print $1;}' `
	passkey=`echo $credentials | awk '{print $2;}' | awk -F":" '{print $2;}' `
	echo "$credentials" > /etc/postfix/sasl_passwd
	chmod 400 /etc/postfix/sasl_passwd
	postmap /etc/postfix/sasl_passwd
	cat /etc/ssl/certs/Thawte_Premium_Server_CA.pem | sudo tee -a /etc/postfix/cacert.pem
	sudo /etc/init.d/postfix reload

	subject_line=`cat subject_line.txt`

	python massMailer.py "$smtp" "$username" "$passkey" "$file_name" "$subject_line"
	return $?
}

export CONFIG_FILE="/etc/massMailer/config.cfg"
CheckArguments $@

if [ -s $CONFIG_FILE ] 
then
	ReadConfigFile
else
	SetDefaultValues $0
fi

CreateListToProcess

for file in ` ls ./temp/$$RUN_* `
do
	echo "File : $file"
	LoadAccountsAndSendMail $file
	rm -f $file
done 

echo "Script completed successfully!!!"
