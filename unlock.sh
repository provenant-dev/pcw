set -e
saved_hash=`head -n 1 ~/.passcode-hash`
hash=""
while true
do
    printf "Enter passcode to unlock wallet: "
    read -s TYPED_PASSCODE
    hash=`echo "$TYPED_PASSCODE" | sha256sum | cut -f1 -d' '`
    if [ "$hash" = "$saved_hash" ]; then
      set +e
      break
    else
      printf "Passcode doesn't match.\n"
    fi
done


