guestfile="/tmp/guest.txt"

if [ -f "$guestfile" ]; then
  guestname=$(head -n 1 "$guestfile")
  printf "\n"
  printf "This guest wallet is currently in use by %s. If you are that person,\n" "$guestname"
  printf "feel free to continue using the wallet in this SSH session. If not, please\n"
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
  printf "Guest wallets are checked out for the duration of a single SSH session plus a\n"
  printf "few minutes (to give you a chance to log back in quickly if you get disconnected).\n"
  printf "Wallet state is automatically reset thereafter.\n"
  printf "\n"
  printf "TERMS OF USE -- If you continue to use this wallet, you agree that:\n"
  printf "\n"
  printf "1. You'll only use the wallet for KERI experiments, not as a platform for\n"
  printf "hacking, random downloads, DOS attacks, SSH tunnels, etc. You won't install\n"
  printf "new stuff or sabotage the wallet.\n"
  printf "\n"
  printf "2. You understand that we offer no warranties or guarantees, and make no\n"
  printf "commitment to provide support. Use at your own risk. However, if something\n"
  printf "seems broken or you have a burning question, please email pcw-guest@provenant.net.\n"
  printf "\n"
  printf "3. You have a license to use the code on this machine ONLY on this machine,\n"
  printf "and only while you are in the current SSH session. You may not copy it\n"
  printf "elsewhere.\n"
  printf "\n"
  printf "4. You have no support rights. You can ask us questions, but we might ignore you.\n"
  printf "\n"
  printf "5. We make no warranties or guarantees of any kind. Use at your own risk.\n"
  printf "\n"
  printf "IF YOU DO NOT AGREE TO THESE TERMS, LOG OFF NOW. OTHERWISE, CHECK OUT THIS WALLET\n"
  printf "BY PROVIDING YOUR EMAIL ADDRESS AS THE RESPONSIBLE PARTY.\n"
  printf "\n"
  read -p "Your email address: " -r email
  echo "$email" > "$guestfile"
fi