set -e
saved_hash=`head -n 1 ~/.passcode-hash`
if [ "$1" = "--debug" ]; then printf "Saved passcode hash = $saved_hash.\n"; fi
hash=""
while true
do
    printf "Enter passcode to unlock wallet: "
    read -s TYPED_PASSCODE
    hash=`echo "$TYPED_PASSCODE" | sha256sum | cut -f1 -d' '`
    if [ "$1" = "--debug" ]; then printf "Hash of that passcode = $hash.\n"; fi
    if [ "$hash" = "$saved_hash" ]; then
      set +e
      break
    else
      hint="${TYPED_PASSCODE:0:2}...${TYPED_PASSCODE:-2:2}"
      printf "Passcode %s doesn't match.\n" $hint
    fi
done


