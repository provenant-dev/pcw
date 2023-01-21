multisigs=$(python3 ~/pcw/aliases.py subset multisig)
if [ $# -lt 1 ]; then
  read -p "Which org alias ($multisigs) do you want to activate? " -r org
else
  org=$1
fi
regex="(^| )${org}(,|$)"
if [[ ! $multisigs =~ $regex ]]; then
  printf "\033[0;33mWarning: ${org} is not the alias of a multi-sig AID.\033[00m\n"
fi
python3 ~/pcw/shellvar.py ORG ~/.bashrc "$org"
export ORG="$org"