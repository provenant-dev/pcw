cleanup() {
  if test -f "$1"; then
    rm -f "$1"
  fi
}

nuke() {
  if test -d "$1"; then
    rm -rf "%1"
}


.bash_history
-rw-r--r--  1 ubuntu ubuntu   220 Jan  6  2022 .bash_logout
-rw-rw-r--  1 ubuntu ubuntu  3839 Nov 22 16:12 .bashrc
-rw-rw-r--  1 ubuntu ubuntu  3771 Nov 22 16:12 .bashrc.bak
drwx------  3 ubuntu ubuntu  4096 Nov  9 09:23 .cache/
drwxrwxr-x  6 ubuntu ubuntu  4096 Nov 22 16:18 .keri/
-rw-rw-r--  1 ubuntu ubuntu   145 Dec  1 08:20 .last-run
-rw-------  1 ubuntu ubuntu    20 Dec  1 10:29 .lesshst
drwxrwxr-x  3 ubuntu ubuntu  4096 Nov 11 14:35 .local/
-rw-rw-r--  1 ubuntu ubuntu  7233 Nov 11 17:46 .log
-rw-r--r--  1 ubuntu ubuntu   833 Dec  1 10:19 .profile
drwx------  2 ubuntu ubuntu  4096 Nov  9 09:08 .ssh/
-rw-r--r--  1 ubuntu ubuntu     0 Nov  9 09:08 .sudo_as_admin_successful
-rw-------  1 ubuntu ubuntu 14439 Dec  1 10:35 .viminfo
drwxrwxr-x  2 ubuntu ubuntu  4096 Nov 11 18:27 bin/
drwxrwxr-x 13 ubuntu ubuntu  4096 Nov 22 16:13 keripy/
drwxrwxr-x  4 ubuntu ubuntu  4096 Dec  1 10:19 pcw/
-rw-rw-r--  1 ubuntu ubuntu  4234 Dec  1 10:19 requirements.log
-rw-rw-r--  1 ubuntu ubuntu     0 Dec  1 10:19 venv.log
drwxrwxr-x  6 ubuntu ubuntu  4096 Dec  1 10:35 vlei-qvi/

if maintain --reset; then
  cleanup ~/.bash_history
  cleanup ~/.last-run
  cleanup ~/.lesshst
  cleanup ~/.log
  cleanup ~/.sudo_as_admin_successful
  cleanup ~/.viminfo
  cleanup ~/*.log
  nuke ~/vlei-qvi
  nuke ~/xar
  nuke ~/keripy
  nuke ~/.cache
  nuke ~/bin
  mkdir ~/bin
fi