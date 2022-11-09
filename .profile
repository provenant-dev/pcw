# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi


# Run the wallet maintenance script at leaast once, and
# up to 3 times to account for relaunches for self patching.
for i in 1 2 3; do
  ~/pcw/maintain.sh
  maintain_err=$?
  if test $maintain_err -ne 0; then break; fi
  if ! test -f ".rerun"; then break; fi
done

if test $maintain_err -eq 0; then
  # Did the script change our .bashrc file, requiring us to re-source?
  if test -f ".bashrc-changed"; then
    rm .bashrc-changed
    source .bashrc
  fi
  # Activate the virtual environment in keripy so kli is in path
  cd ~/keripy && source venv/bin/activate
  # Change to the folder where we can run prepared scripts
  cd ~/vlei-qvi
else
  printf "Wallet maintenance didn't succeed cleanly. This is not a\n"
  printf "a good outcome, but it may be okay if you simply pressed\n"
  printf "CTRL+C or otherwise interrupted a process that was not\n"
  printf "strictly necessary.\n"
  printf "\n"
  printf "You may attempt to continue by running the following two\n"
  printf "commands:\n"
  printf "\n"
  printf "  source keripy/venv/bin/activate\n"
  printf "  cd vlei-qvi\n"
  printf "\n"
  printf "You can also inspect ~/*.log files or contact support with\n"
  printf "those files plus any error messages shown on the screen.\n"
fi
