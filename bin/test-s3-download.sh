#!/bin/bash

filename="/tmp/s3-file.downloaded"
rm -f $filename

read -p "Enter the name on S3 of the new credential: " -r obj

printf "Launching share-via-s3\n"
share-via-s3 download --obj "$obj" --file "$filename"
ls -al "$filename"
printf "Exiting test download script.\n"