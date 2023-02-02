# Do we need to run the wallet reset command?
if test -d ~/keripy; then
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
rm -f ~/.os-patch-check
rm -f ~/*.log
rm -f ~/.*.log
rm -f ~/.restart-url
rm -rf ~/pcw/upgraders/__pycache__
rm -rf ~/vlei-qvi
rm -rf ~/xar
rm -rf ~/keripy
rm -rf ~/.cache
rm -rf ~/.vim
rm -rf ~/bin
mkdir ~/bin
sudo crontab -r
crontab -r
