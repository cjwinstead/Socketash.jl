#!/bin/bash
PORT=5432

if [ $# != 2 ]; then
    printf "    Usage:     $0 command argument\n"
    exit 1
fi

# Check is server is listening
printf "Socketash.ping\n\n//EOF\n" | nc localhost $PORT > /dev/null
if [ $? != 0 ]; then
    printf "Server not listening\n"
    exit 1
fi


if [ $1 == "uppercase" ]; then
    printf "uppercase\n%s\n//EOF\n" "$2" | nc localhost $PORT
elif [ $1 == "strlen" ]; then
    printf "strlen\n%s\n//EOF\n" "$2" | nc localhost $PORT
fi

