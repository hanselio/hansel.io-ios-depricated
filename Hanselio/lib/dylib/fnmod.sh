#!/bin/sh

unset string
while getopts s: option
do
	case $option in
		s)
			string=$OPTARG
			;;
		*)
       		echo "Invalid argument"
        ;;
	esac
done

sed -e '
s/^.*func \{1,\}//
s/ *->.*$//
s/:[^,)]\{1,\}/:/g
s/\([^,] \{1,\}\)[^:[:space:]]\{1,\}:/\1:/g
s/[, ]//g
' <<< "$string"


