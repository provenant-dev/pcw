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
# is more generic, allowing the same scripts to be used for Legal
# Entities represented by individuals who are LARs (LE
# Authorized Representatives). To use GLEIF's scripts with minimal,
# changes, we declare environment variables in their generic form,
# and then map them to the values GLEIF's scripts expect.

# What is the name of the DB where local state will be stored?
DB_NAME="XAR"
# The alias you will use locally to refer to the single-sig AID
# that identifies you as an individual representative of your org.
MY_ALIAS="me@my-org"
# The alias you will use locally to refer to the multi-sig AID
# that identifies your org to the outside world.
MY_ORG_ALIAS="my-org"

# Now map our choices into the variables expected by GLEIF scripts.
export QAR_NAME=$DB_NAME
export QAR_ALIAS=$MY_ALIAS
export QAR_AID_ALIAS=$MY_ORG_ALIAS
export QAR_REG_NAME="${MY_ORG_ALIAS}-registry"

if [[ ! "$QAR_AID_ALIAS" =~ "my-org" ]]; then
  printf "Org=$QAR_AID_ALIAS, personal=$QAR_ALIAS, registry=$QAR_REG_NAME\n"
fi

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
