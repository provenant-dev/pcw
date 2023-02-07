#!/usr/bin/env bash

# If wallet is already unlocked, short-circuit.
hash=`printf "$TYPED_PASSCODE" | sha256sum | cut -f1 -d' '`
if [ "$hash" = "$saved_hash" ]; then
  # Make sure that TYPED_PASSCODE is exported so it can be used elsewhere.
  export TYPED_PASSCODE=$TYPED_PASSCODE
  printf "Wallet unlocked.\n"
  return
fi

# Also short-circuit if we're using a hardcoded passcode for developer convenience.
saved_hash=`head -n 1 ~/.passcode-hash`
if [ "$saved_hash" = "4aa6892909e369933b9f1babc10519121e2dfd1042551f6b9bdd4eae51f1f0c2" ] ; then
  printf "Using hard-coded passcode.\n"
  export TYPED_PASSCODE="111111111111111111111"
  return
fi

if [ "$1" = "--debug" ]; then printf "Saved passcode hash = $saved_hash.\n"; fi

printf "\n"
hash=""
reprompt="true"
trap 'reprompt="false"' INT
while :
do
    printf "\033[0;33mEnter 21-char passcode to unlock wallet:\033[00m "
    # Get input from user (and if CTRL+C is pressed, break immediately).
    POSIXLY_CORRECT=1 read -s TYPED_PASSCODE

    # If we got here because of CTRL+C, quit gracefully with warning.
    if [ "$reprompt" = "false" ]; then
      printf "\r\033[0;31mUnknown passcode makes wallet temporarily unusable for KERI tasks.\033[00m\n"
      return
    fi

    # Evaluate by comparing hash of passcode to stored hash. If they match, then
    # we can set TYPED_PASSCODE to what the user provided, and we know KERI will
    # be able to unlock the wallet, so we're done prompting. Otherwise, prompt
    # the user to try again.
    hash=`printf "$TYPED_PASSCODE" | sha256sum | cut -f1 -d' '`
    if [ "$1" = "--debug" ]; then printf "Hash of that passcode = $hash.\n"; fi
    if [ "$hash" = "$saved_hash" ]; then
      printf "\rWallet unlocked."
      # Clear till end of line
      tput el
      printf "\n"
      export TYPED_PASSCODE="$TYPED_PASSCODE"
      break
    else
      len=${#TYPED_PASSCODE}
      if [ $len -lt 5 ]; then
        hint="${TYPED_PASSCODE:0:1}..."
      else
        hint="${TYPED_PASSCODE:0:2}...${TYPED_PASSCODE: -2:2}"
      fi
      printf "\r\033[0;31mPasscode %s (%d chars) doesn't match.\033[00m" $hint ${#TYPED_PASSCODE}
      tput el
      printf "\n"
    fi
done

# Make sure CTRL+C is no longer trapped by the handler from this script.
trap - INT
