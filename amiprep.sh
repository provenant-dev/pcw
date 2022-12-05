# Do we need to run the wallet reset command?
if test -f ~/keripy; then
  if ! /usr/bin/env python3 ~/pcw/maintain.py --reset; then
    exit 1
  fi
fi
rm -f ~/.bash_history
rm -f ~/.last-run
rm -f ~/.lesshst
rm -f ~/.log
rm -f ~/.sudo_as_admin_successful
rm -f ~/.viminfo
rm -f ~/.python_history
rm -f ~/.passcode-hash
rm -f ~/*.log
rm -f ~/.maintain.log
rm -rf ~/vlei-qvi
rm -rf ~/xar
rm -rf ~/keripy
rm -rf ~/.cache
rm -rf ~/bin
mkdir ~/bin