saved_hash=`head -n 1 ~/.passcode-hash`
if [ "$1" = "--debug" ]; then printf "Saved passcode hash = $saved_hash.\n"; fi
hash=""
while true
do
    printf "\033[0;34mEnter 21-char passcode to unlock wallet:\033[00m "
    read -s TYPED_PASSCODE
    # Erase previous line.
    tput cuu1 && tput cuu1 && tput el
    hash=`printf "$TYPED_PASSCODE" | sha256sum | cut -f1 -d' '`
    if [ "$1" = "--debug" ]; then printf "Hash of that passcode = $hash.\n"; fi
    if [ "$hash" = "$saved_hash" ]; then
      printf "Wallet unlocked.\n"
      export TYPED_PASSCODE=$TYPED_PASSCODE
      break
    else
      len=${#TYPED_PASSCODE}
      if [ $len -lt 5 ]; then
        hint="${TYPED_PASSCODE:0:1}..."
      else
        hint="${TYPED_PASSCODE:0:2}...${TYPED_PASSCODE: -2:2}"
      fi
      printf "Passcode %s (%d chars) doesn't match.\n" $hint ${#TYPED_PASSCODE}
    fi
done

