guestfile="/tmp/guest.txt"

if [ -f "$guestfile" ]; then
  guestname=$(head -n 1 "$guestfile")
  printf "\n"
  printf "This guest wallet is currently in use by %s. If you are that person,\n" "$guestname"
  printf "feel free to continue using the wallet in the current SSH session. If not, please\n"
  printf "try a different guest wallet, or check back in an hour to see if this one frees up.\n"
  printf "\n"
  printf "Are you %s (yes/no)? " "$guestname"
  read -r answer
  if [ ! "$answer" = "yes" ]; then
    exit
  fi
else
  printf "\n"
  printf "Welcome. This guest wallet is a tool you can use to do KERI experiments with\n"
  printf "low risk. Feel free to create AIDs, connect them to one another, issue\n"
  printf "credentials, try various commands with the KERI kli tool, and so forth. All\n"
  printf "operations use stage witnesses rather than production ones. Any data you\n"
  printf "create is temporary.\n"
  printf "\n"
  printf "Guest wallets are checked out for the duration of a single SSH session. When,\n"
  printf "until you either "
fi