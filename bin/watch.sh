# Make sure wallet is initialized.
pkli list >/dev/null &2>1
if [ $? -ne 0 ]; then
  printf "Your wallet is empty. First step is to run create-local-aid.\n"
else
  printf "Syncing wallet with witnesses.\n\n" && pkli local watch
fi
