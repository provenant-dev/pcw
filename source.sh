#!/bin/bash

##################################################################
##                                                              ##
##       Init script for a Provenant Command-Line Wallet        ##
##                                                              ##
##################################################################

# The name you want to use for your local database.
export QAR_NAME="XAR"

# The name you want for the alias for your local QAR AID
export QAR_ALIAS="me"

# Change to the name you want for the alias for your group multisig AID
export QAR_AID_ALIAS="my-org"

# Change to the name you want for the registry for your QVI
export QAR_REG_NAME="my-org-registry"

# Set current working directory for all scripts that must access files
QAR_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export QAR_SCRIPT_DIR="${QAR_DIR}/scripts"
export QAR_DATA_DIR="${QAR_DIR}/data"

set_passcode() {
}
export -f set_passcode >/dev/null 2>&1

get_passcode() {
    echo $TYPED_PASSCODE
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
