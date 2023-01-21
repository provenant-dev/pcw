alias maintain='/usr/bin/env python3 ~/pcw/maintain.py'
alias help='printf "Please load https://bit.ly/3Cx4zD2 in your browser.\n"'
alias unlock='source ~/pcw/unlock.sh'
alias set-person='source ~/pcw/set-person.sh'
alias set-org='source ~/pcw/set-org.sh'

# Run the wallet maintenance script at least once, and
# up to 3 times to account for relaunches for self patching.
for i in 1 2 3; do
  python3 ~/pcw/maintain.py
  maintain_err=$?
  if test $maintain_err -ne 0; then break; fi
  if ! test -f ".rerun"; then break; fi
done

if test $maintain_err -eq 0; then
  # Did the script change our .bashrc file, requiring us to re-source?
  if test -f ".bashrc-changed"; then
    rm ".bashrc-changed"
    source .bashrc
  fi
  # Activate the virtual environment in keripy so kli is in path
  printf "\nActivating virtual environment.\n"
  cd ~/keripy && source venv/bin/activate >~/venv.log 2>&1 && pip install -r requirements.txt >~/requirements.log 2>&1; cd ~/
  # Even though blessings is installed in the OS, it's not installed
  # in the venv. Force it to be there as well, so we can run our
  # maintenance script cleanly.
  pip install blessings >/dev/null 2>&1
  which kli >/dev/null 2>&1
  if test $? -eq 0; then
    unlock && printf "\nReady. Try 'help' if you need guidance.\n\n"
  else
    printf "\nError: kli is not on the path. Check ~/venv.log and ~/requirements.log.\n\nSupport: vlei-support@provenant.net\n\n"
  fi
else
  printf "\n"
  printf "Wallet maintenance didn't succeed cleanly. This is not a good outcome, but it\n"
  printf "*might* be okay if you simply pressed CTRL+C during a process that wasn't\n"
  printf "strictly necessary, or if you're doing development work on the wallet.\n"
  printf "\n"
  printf "You could attempt to continue by sourcing ~/keripy/venv/bin/activate, or you\n"
  printf "could troubleshoot by inspecting ~/*.log files.\n"
  printf "\n"
  printf "If you're lost, contact support (vlei-support@provenant.net) with any error\n"
  printf "messages shown on the screen.\n"
fi
cd ~/
