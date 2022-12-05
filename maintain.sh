alias maintain='/usr/bin/env python3 ~/pcw/maintain.py'

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
  printf "\nSetting up virtual environment.\n"
  cd ~/keripy
  source venv/bin/activate >~/venv.log 2>&1 && pip install -r requirements.txt >~/requirements.log 2>&1
  # Even though blessings is installed in the OS, it's not installed
  # in the venv. Force it to be there as well, so we can run our
  # maintenance script cleanly.
  pip install blessings >/dev/null 2>&1
  which kli >/dev/null 2>&1
  if test $? -eq 0; then
    source ~/pcw/unlock.sh && printf "\nWallet is ready.\n\n"
  else
    printf "\nError: kli is not on the path. Check ~/venv.log and ~/requirements.log.\n\n"
  fi
else
  printf "\nWallet maintenance didn't succeed cleanly. This is not a\n"
  printf "a good outcome, but it may be okay if you simply pressed\n"
  printf "CTRL+C or otherwise interrupted a process that was not\n"
  printf "strictly necessary.\n"
  printf "\n"
  printf "You may attempt to continue by running the following\n"
  printf "command:\n"
  printf "\n"
  printf "  source keripy/venv/bin/activate\n"
  printf "\n"
  printf "You can also inspect ~/*.log files or contact support with\n"
  printf "those files plus any error messages shown on the screen.\n"
fi
cd ~/