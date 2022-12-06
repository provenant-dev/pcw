import hashlib
import os
import re
import shutil
import string
import sys
import time
import secrets
import stat

import blessings


MY_FOLDER = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.expanduser("~/.maintain.log")
PATCH_CHECK_FILE = os.path.expanduser("~/.os-patch-check")
PASSCODE_FILE = os.path.expanduser("~/.passcode-hash")
RESET_PROMPT = """
Resetting state is destructive. It removes your history, all your AIDs,
and all your keys. It breaks any connections you've built by exchanging
OOBIs. Any credentials you've received or issued become unusable, and all
multisig schemes where you are a member lose your contribution. They may
have to be rebuilt, which means that others may be affected by the operation.
Your passcode is also reset, so you will have to choose a new one and re-save
it in your password manager.

This is basically like creating a brand new wallet.

Type "yes" to confirm, or anything else to cancel."""
PROTECT_PROMPT = """
This wallet has high stakes. You need strong protections around it, because
it is the basis for controlling your personal and corporate identity.

You are responsible for two of these layers. One is the SSH key that
you created. Combined with the connection instructions we provide, this
key should keep your data safe, all on its own.

However, once you're in the wallet, we add a final layer of protection: your
data is encrypted at rest, protected by a passcode and a salt. We generate
both of these values randomly to guarantee their entropy. Your salt is stored,
but the passcode is something you must remember on your own and supply each
time you login. We recommend that you store it in a password manager like
LastPass or 1Password. Your wallet will be unusable without it, and Provenant
has no way to recover if you forget it, since we do not keep a copy for you.

Your passcode is:
  """
RERUNNER = '.rerun'
ESC_SEQ_PAT = re.compile("(?:\007|\033)\\[[0-9;]+[Bm]")
BIN_PATH = os.path.expanduser("~/bin")

log = open(LOG_FILE, 'at')
term = blessings.Terminal()

MAINTENANCE_COLOR = term.dim_yellow
SCRIPT_PERMISSIONS = stat.S_IXUSR | stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IROTH


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


class TempColor:
    """
    Changed working directory until python context is reset, then
    changes back.
    """
    def __init__(self, color, restore=None):
        self.color = color
        self.restore = restore if restore else term.normal

    def __enter__(self):
        sys.stdout.write(self.color)

    def __exit__(self, exc_type, exc_val, exc_tb):
        sys.stdout.write(self.restore)


def cout(txt):
    sys.stdout.write(txt)
    sys.stdout.flush()
    log.write(ESC_SEQ_PAT.sub("", txt))
    log.flush()


def ask(question):
    # Undo dimness of maintenance text.
    sys.stdout.write(term.normal)
    cout(term.yellow(question) + "\n")
    cout(term.red(">> "))
    with TempColor(term.white, MAINTENANCE_COLOR):
        answer = input().strip()
    return answer


def run(cmd):
    exitcode = os.system(cmd + f" >.last-run 2>&1")
    if exitcode:
        with TempColor(term.normal + term.red, MAINTENANCE_COLOR):
            cout("System command exited with code %d. Command was:\n  %s\n" % (exitcode, cmd))
            with open('.last-run', 'wt') as f:
                output = f.read()
            cout(output)
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


def is_protected():
    return os.path.isfile(PASSCODE_FILE)


PASSCODE_SIZE = 21
PASSCODE_CHARS = string.ascii_lowercase + string.ascii_uppercase + '123456789'


def get_passcode():
    code = []
    for x in range(PASSCODE_SIZE):
        code.append(PASSCODE_CHARS[secrets.randbelow(len(PASSCODE_CHARS))])
    return "".join(code)


def protect():
    # In this function, we switch between sys.stdout and cout very deliberately.
    # cout() writes to the log, whereas sys.stdout only writes to the screen.
    # We want the log to contain almost, but not quite, what we write to the
    # screen, so that the passcode is not stored in the log.

    # Temporarily undo dimness of maintenance text.
    with TempColor(term.normal):
        cout(term.yellow(PROTECT_PROMPT))
        passcode = get_passcode()
        sys.stdout.write(term.red(passcode))
        sys.stdout.write(term.white("  << Press ENTER when you've saved this passcode."))
        input()
        sys.stdout.write(term.move_up + "  ")
        cout("*" * 21)
        sys.stdout.write(" " * (term.width - 24) + "\n")
    digest = hashlib.sha256(passcode.encode("ASCII")).hexdigest()
    with open(PASSCODE_FILE, 'wt') as f:
        f.write(digest)
