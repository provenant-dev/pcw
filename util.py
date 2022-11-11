import os
import re
import shutil
import sys
import time

import blessings


LOG_FILE = os.path.expanduser("~/.maintain.log")
PATCH_CHECK_FILE = os.path.expanduser("~/.os-patch-check")
RESET_PROMPT = """\
Resetting state is destructive. It removes your history, all your AIDs,
and all your keys. All credentials you've received or issued become
unusable, and all multisigs where you are a participant lose your input.
It is basically like creating a brand new wallet. Type "yes" to confirm."""
RERUNNER = '.rerun'
ESC_SEQ_PAT = re.compile("(?:\007|\033)\\[[0-9;]+[Bm]")

log = open(LOG_FILE, 'at')
term = blessings.Terminal()


class TempWorkingDir:
    """
    Changed working directory until python context is reset, then
    changes back.
    """
    def __init__(self, path):
        self.reset = os.getcwd()
        self.path = path

    def __enter__(self):
        os.chdir(self.path)

    def __exit__(self, exc_type, exc_val, exc_tb):
        os.chdir(self.reset)


def cout(txt):
    sys.stdout.write(txt)
    sys.stdout.flush()
    log.write(ESC_SEQ_PAT.sub("", txt))
    log.flush()


def ask(question):
    cout(term.bright_yellow(question) + '\n   ')
    cout(term.bright_red + ">> " + term.white)
    try:
        answer = input().strip()
    finally:
        cout(term.normal)
    return answer


def run(cmd):
    exitcode = os.system(cmd + f" >{LOG_FILE} 2>&1")
    if exitcode:
        cout(term.bright_red + "System command exited with code %d. Command was:" + term.normal + "\n  %s\n" % (exitcode, cmd))
    return exitcode


def backup_file(fname, once_only=True):
    backup_name = fname + '.bak'
    if not os.path.isfile(backup_name) or not once_only:
        log.write("Backing up %s to %s.\n" % (fname, backup_name))
        shutil.copyfile(fname, backup_name)


def restore_from_backup(fname):
    backup_name = fname + '.bak'
    if os.path.isfile(backup_name):
        log.write("Restoring %s from %s.\n" % (fname, backup_name))
        shutil.copyfile(backup_name, fname)
        return True


def time_since(file_modified):
    now = time.time()
    if os.path.isfile(file_modified):
        elapsed = now - os.stat(file_modified).st_mtime
    else:
        elapsed = now
    return elapsed


def get_shell_variable(variable, script):
    var_pat = re.compile(r'^\s*' + variable + r'\s*=\s*"([^"]+)"\n', re.MULTILINE)
    m = var_pat.search(script)
    if m:
        return m.group(1)


