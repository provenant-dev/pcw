singlesigs=$(python3 ~/pcw/aliases.py subset singlesig)
if [ $# -lt 1 ]; then
  read -p "Which person alias ($singlesigs) do you want to activate? " -r person
else
  person=$1
fi
regex="(^| )${person}(,|$)"
if [[ ! $singlesigs =~ $regex ]]; then
  printf "Warning; ${person} is not a single-sig AID."
fi
#python3 shellvar OWNER ~/.bashrc "$person"
export OWNER="$person"
