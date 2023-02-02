saved_hash=`head -n 1 ~/.passcode-hash`
if [ "$saved_hash" = "4aa6892909e369933b9f1babc10519121e2dfd1042551f6b9bdd4eae51f1f0c2" ] ; then
  printf "Short-circuited passcode since this is not a production wallet.\n"
  export TYPED_PASSCODE="111111111111111111111"
else
  if [ "$1" = "--debug" ]; then printf "Saved passcode hash = $saved_hash.\n"; fi
  printf "\n"
  hash=""
  trap 'printf "\r\033[0;31mUnknown passcode makes wallet temporarily unusable for KERI tasks.\033[00m\n" && return' INT
  while true
  do
      printf "\033[0;33mEnter 21-char passcode to unlock wallet:\033[00m "
      read -s TYPED_PASSCODE
      hash=`printf "$TYPED_PASSCODE" | sha256sum | cut -f1 -d' '`
      if [ "$1" = "--debug" ]; then printf "Hash of that passcode = $hash.\n"; fi
      if [ "$hash" = "$saved_hash" ]; then
        printf "\rWallet unlocked."
        # Clear till end of line
        tput el
        printf "\n"
        export TYPED_PASSCODE=$TYPED_PASSCODE
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
fi

