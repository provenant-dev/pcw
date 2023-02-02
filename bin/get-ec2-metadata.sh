#!/usr/bin/env bash

if test "$#" -ne 1; then
  url="/latest/dynamic/instance-identity/document"
else
  url=$1
fi

TOKEN=`curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/${url}
