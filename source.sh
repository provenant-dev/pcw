#!/bin/bash

##################################################################
##                                                              ##
##          Initialization script for a Provenant Wallet        ##
##                                                              ##
##################################################################

# Change to the name you want to use for your local database environment.
export QAR_NAME="QAR"

# Change to the name you want for the alias for your local QAR AID
export QAR_ALIAS=""

# Set current working directory for all scripts that must access files
QAR_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set_passcode() {
    head -n 1 passcode >/dev/null 2>&1
    ret=$?
    if [ $ret -eq 1 ]; then
      echo "Generating passcode"
      kli passcode generate > passcode
    fi
}
export -f set_passcode >/dev/null 2>&1

get_passcode() {
    echo $(head -n 1 passcode)
}
export -f get_passcode >/dev/null 2>&1

set_salt() {
      head -n 1 salt >/dev/null 2>&1
      ret=$?
      if [ $ret -eq 1 ]; then
        echo "Generating salt"
        kli salt > salt
      fi
}

get_salt() {
    echo $(head -n 1 salt)
}
export -f get_salt >/dev/null 2>&1

set_passcode $1
set_salt $1
