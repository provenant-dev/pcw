#!/bin/bash

filename="/tmp/s3-file.uploaded"
rm -f $filename

printf "Launching share-via-s3\n"
share-via-s3 upload --file "$filename" &

sleep 2
printf "Creating %s to share.\n" "$filename"
ls ~/ > "$filename"
ls -al "$filename"

wait
printf "Exiting test upload script.\n"