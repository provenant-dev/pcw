#!/bin/bash

##################################################################
##                                                              ##
##      Config script for a Provenant Command-Line Wallet       ##
##                                                              ##
##################################################################

# PCW code is based on GLEIF's vlei-qvi repo, which assumes that
# the org whose identity is under management is a QVI (Qualified
# vLEI Issuer), and that the person who owns the wallet is a QAR
# (QVI Authorized Representative). Provenant's command-line wallet
# is more generic, allowing the same scripts to be used for QVIs
# but also be used for Legal Entities represented by individuals
# who are LARs (LE Authorized Representatives). To use GLEIF's
# scripts with minimal changes, we manage environment variables
# in their generic form ($OWNER, $ORG, $WALLET_DB_NAME in
# ~/.bashrc. These are all set at login, and can be manipulated
# in the environment and .bashrc at the same time with the
# "set-person" and "set-org" commands. We use this script to map
# these generic variables to the values that GLEIF's scripts expect.

# Now map our choices into the variables expected by GLEIF scripts.
export QAR_NAME=$WALLET_DB_NAME
export QAR_ALIAS=$OWNER
export QAR_AID_ALIAS=$ORG
export QAR_REG_NAME="${ORG}-registry"

# Set current working directory for all scripts that must access files
QAR_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export QAR_SCRIPT_DIR="${QAR_DIR}/scripts"
export QAR_DATA_DIR="${QAR_DIR}/data"

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

set_salt $1
