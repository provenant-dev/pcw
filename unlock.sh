set -e
saved_hash=`head -n 1 ~/.passcode-hash`
if [ "$1" = "--debug" ]; then printf "Saved passcode hash = $saved_hash.\n"
hash=""
while true
do
    printf "Enter passcode to unlock wallet: "
    read -s TYPED_PASSCODE
    hash=`echo "$TYPED_PASSCODE" | sha256sum | cut -f1 -d' '`
    if [ "$1" = "--debug" ]; then printf "Hash of that passcode = $hash.\n"
    if [ "$hash" = "$saved_hash" ]; then
      set +e
      break
    else
      printf "Passcode doesn't match.\n"
    fi
done


