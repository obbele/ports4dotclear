#!/bin/sh -e
# Old script to publish an article
# depend on an old version of RewriteURLs which only took one argument :
# "root_url" aka "files"
# 
# superseed by publish.pl which manage separately each file in Media/*

XHTML=$1
CONFIG=$2
LOG=publish.log
SCRIPTS=../../Scripts
TMP=/tmp/foo.xhtml
XMLRPC=../../XML-RPC/dotclear.py
usage()
{
	echo 2>&1 "Usage: $0 doc.xhtml [ConfigName]"
	exit 1
}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	usage
fi

# If config is not given as command line argument
if [ -z "$CONFIG" ]; then
	CONFIG=`tail -n 1 $LOG | cut -f 1`
	if [ -z "$CONFIG" ]; then
		echo 2>&1 "Error: cannot find config file name"
		exit 2
	fi
fi

ROOT_URL=`$XMLRPC --conf=$CONFIG --files |\
			awk '/public_files =/ {print $3}'`
echo "Rewriting URLs with root URL = [$ROOT_URL]"
$SCRIPTS/RewriteURLs.pl $ROOT_URL <$XHTML >$TMP
mv $TMP $XHTML

# Try to retrieve ID from a precedent publish.sh invocation
# if no data is found, create a new message
ID=`awk "/$CONFIG/ {print \\\$2}" $LOG`
if [ -z "$ID" ]; then
	echo "Posting new message on [$CONFIG]"
	$XMLRPC --conf=$CONFIG --new --raw=${XHTML}
	LAST_ID=`$XMLRPC --conf=$CONFIG --list=1 |\
				awk '/^[[:digit:]]+/ {printf $1}'`
	echo "$CONFIG	$LAST_ID	`date +%Y-%m-%d`" >>$LOG
else
	echo "Editing previous message #$ID on [$CONFIG]"
	$XMLRPC --conf=$CONFIG --edit=$ID --raw=${XHTML}
fi
