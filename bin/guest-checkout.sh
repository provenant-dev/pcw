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
  printf "Guest wallets are checked out for the duration of a single SSH session plus a\n"
  printf "few minutes (to give you a chance to log back in quickly if you get disconnected).\n"
  printf "\n"
  printf "TERMS OF USE: BY CONTINUING TO USE THIS WALLET, YOU AGREE THAT YOU WILL NOT HACK\n"
  printf "THE SOFTWARE, USE IT OR THE OS FOR ANY NON-KERI-RELATED PURPOSES, OR OTHERWISE\n"
  printf "BEHAVE IN A WAY THAT COULD BE CONSTRUED AS MALICIOUS OR AT ODDS WITH PROVENANT'S\n"
  printf "INTENDED USE FOR EDUCATION AND PUBLIC SERVICE. YOU WILL LEAVE THE MACHINE IN\n"
  printf "GOOD WORKING CONDITION FOR THE NEXT GUEST, AND YOU WILL NOTIFY PROVENANT AT\n"
  printf "pcw-guest@provenant.net IF ANY REPAIR OR MAINTENANCE IS NEEDED. YOU ALSO CONSENT\n"
  printf "THAT PROVENANT CAN MONITOR YOUR WALLET SESSION TO ENFORCE GOOD BEHAVIOR.\n"
  printf "\n"
  printf "IF YOU DO NOT AGREE TO THESE TERMS, LOG OFF NOW. OTHERWISE, CHECK OUT THIS WALLET\n"
  printf "BY PROVIDING YOUR EMAIL ADDRESS AS THE RESPONSIBLE PARTY.\n"
  printf "\n"
  read -p "Your email address: " -r email
  echo "$email" > "$guestfile"
fi