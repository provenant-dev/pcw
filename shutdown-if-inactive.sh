#!/bin/bash
#
# Shuts down the wallet host if it has no active SSH session for a while.
# Wallet can be restarted by curling https://start.wallet.provenant.net/user@email.
#
# This script is designed to be executed as root from a cron job. It will power
# off the host on the 2nd consecutive run without an active ssh session, or if
# the last ssh session was closed more than 30 minutes ago. That prevents an
# undesirable shutdown when the machine was just started, or on a brief disconnect.
#
# To enable, run sudo crontab -l /home/ubuntu/pcw/shutdown-if-inactive.crontab
#

MARKER_FILE="/tmp/ssh-inactive-flag"

STATUS=$(netstat | grep ssh | grep ESTABLISHED &>/dev/null)
if [ $? -eq 0 ]; then
  STATUS="active"
  #echo $(date) ": active SSH connection"
else
  echo $(date) ": no active SSH connection"
  STATUS="inactive"
fi

if [ "$STATUS" == "inactive" ]; then
  if [ -f "$MARKER_FILE" ]; then

    # If someone logged in within the last 30 minutes, don't shut down.
    if ! last --since "30 minutes ago" | grep -q "pts/"; then
      echo $(date) ": Shutting down due to no ssh activity for 30 minutes."
      poweroff
    fi

  else
    # Create a marker file so that it will shut down if still inactive on the next time this script runs.
    touch "$MARKER_FILE"
  fi
else
  # Delete marker file if it exists
  rm --force "$MARKER_FILE"
fi