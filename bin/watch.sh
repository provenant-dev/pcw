# Watching witnesses only makes sense if we actually have AIDs defined.
aliases="$(pkli list 2>&1)"
regex="eystore must already exist"
if [[ "$aliases" =~ $regex ]]; then
  printf "Your wallet is empty. First step is to run create-local-aid.\n"
else
  printf "Syncing wallet with witnesses.\n\n" && pkli local watch
fi