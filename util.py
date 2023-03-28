import hashlib
import json
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
This wallet has high stakes. You need strong protections around it.

You are responsible for two of these protections. One is the SSH key that you
use for remote access. Combined with the connection instructions we provide,
this key should keep your data safe, all on its own.

However, once you're in the wallet, there's a final layer of protection: your
data is encrypted at rest, protected by a passcode and a salt. The passcode
is something you must remember. You are prompted for it with each login, and
you cannot use the wallet for KERI tasks without it. We recommend that you
store it in a password manager like LastPass or 1Password. Provenant has no
way to recover if you forget it, since we do not keep a copy for you.

Your passcode is:
  """
HARDCODED_PROTECT_PROMPT = """
Since this is NOT currently being used as a production wallet, we use a hard-
coded passcode to decrease friction, and we mostly short-circuit the places
where it's needed. If you reset this wallet and put it in production mode,
you'll get a new passcode that actually matters, and it will be vital that
you remember it. In the meantime, the passcode for this wallet is just the
1 digit, repeated 21 times): 

  """
HARDCODED_PASSCODE = '111111111111111111111'
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


def sys_call_with_output(cmd):
    tmp = ".tmp-output"
    exit_code = os.system(cmd + f" >{tmp} 2>&1")
    if os.path.isfile(tmp):
        with open(tmp, "rt") as f:
            output = f.read()
        os.remove(tmp)
    else:
        output = ""
    return exit_code, output


def sys_call_with_output_or_die(cmd):
    exit_code, output = sys_call_with_output(cmd)
    if exit_code != 0:
        print(f"Ran {cmd}. Expected success; got code {exit_code} with this output instead:\n" + output)
        sys.exit(127)
    return output


_guest_mode_active = None
def guest_mode_is_active():
    global _guest_mode_active
    if _guest_mode_active is None:
        exit_code, hostname = sys_call_with_output('hostname')
        _guest_mode_active = bool('guest' in hostname.lower() if hostname else False)
    return _guest_mode_active


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


def shell_variable_pat(variable):
    return re.compile(r'^[ \t]*(export\s+)?' + variable + r'\s*=\s*"([^"]*)"[ \t]*(\n|\r|$)', re.MULTILINE)


def is_executable(path):
    return bool(os.stat(path).st_mode & stat.S_IXUSR)


def get_shell_variable(variable, script):
    var_pat = shell_variable_pat(variable)
    m = var_pat.search(script)
    if m:
        return m.group(2), m.group(1).startswith("export") if m.group(1) else False, m.start(), m.end()
    return None, False, 0, 0


def set_or_update_shell_variable(variable, script, value, export=False, top=True):
    var_pat = shell_variable_pat(variable)
    new_line = ("export " if export else "") + f'{variable}="{value}"' + '\n'
    m = var_pat.search(script)
    if m:
        return script[:m.start()] + new_line + script[m.end():]
    else:
        return (new_line + script.lstrip()) if top else (script.rstrip() + new_line)


def is_protected_by_passcode():
    return os.path.isfile(PASSCODE_FILE)


PASSCODE_SIZE = 21
PASSCODE_CHARS = string.ascii_lowercase + string.ascii_uppercase + '123456789'


def get_passcode():
    code = []
    for x in range(PASSCODE_SIZE):
        code.append(PASSCODE_CHARS[secrets.randbelow(len(PASSCODE_CHARS))])
    return "".join(code)


def protect_by_passcode(hardcode=False, quiet=False):
    # In this function, we switch between sys.stdout and cout very deliberately.
    # cout() writes to the log, whereas sys.stdout only writes to the screen.
    # We want the log to contain almost, but not quite, what we write to the
    # screen, so that the passcode is not stored in the log.

    # Temporarily undo dimness of maintenance text.
    with TempColor(term.normal, MAINTENANCE_COLOR):
        if hardcode:
            passcode = HARDCODED_PASSCODE
            if not quiet:
                cout(term.yellow(HARDCODED_PROTECT_PROMPT))
                sys.stdout.write(term.red(passcode) + "\n")
        else:
            cout(term.yellow(PROTECT_PROMPT))
            passcode = get_passcode()
            sys.stdout.write(term.red(passcode))
            sys.stdout.write(term.white("  << Press ENTER when you've saved this passcode.\n"))
            input()
            sys.stdout.write(term.move_up + term.move_up + "  ")
            cout("*" * 21)
            sys.stdout.write(" " * (term.width - 24) + "\n")
    digest = hashlib.sha256(passcode.encode("ASCII")).hexdigest()
    with open(PASSCODE_FILE, 'wt') as f:
        f.write(digest)


_ec2_metadata = {}
def get_ec2_metadata():
    """
    Expect something like this:
{
  "accountId" : "607632564583",
  "architecture" : "x86_64",
  "availabilityZone" : "us-east-1e",
  "billingProducts" : null,
  "devpayProductCodes" : null,
  "marketplaceProductCodes" : null,
  "imageId" : "ami-0ff0f2edab8a12775",
  "instanceId" : "i-099981241c77999b3",
  "instanceType" : "t2.micro",
  "kernelId" : null,
  "pendingTime" : "2023-02-02T11:51:36Z",
  "privateIp" : "172.31.60.196",
  "ramdiskId" : null,
  "region" : "us-east-1",
  "version" : "2017-09-30"
}
    """
    global _ec2_metadata
    if not _ec2_metadata:
        exit_code, output = sys_call_with_output("get-ec2-metadata")
        if not exit_code:
            try:
                _ec2_metadata = json.loads(output)
            except:
                pass
    return _ec2_metadata


def is_hosted_on_provenant_aws():
    return bool(get_ec2_metadata().get("accountId","") == "607632564583")


RESTART_URL = "~/.restart-url"

NO_AUTO_SHUTDOWN_EXPLANATION = """
This wallet is not hosted on Provenant's AWS cloud. That means your org incurs
the cost of keeping it running. You may wish to work with your devops team to
optimize those costs by shutting down the wallet when no active work is
needed.
"""

AUTO_SHUTDOWN_EXPLANATION = """
Because this wallet is hosted on Provenant's AWS cloud, it tries to minimize
costs by shutting itself off automatically when no SSH sessions are active for
more than 30 minutes. To restart it, visit your wallet start page in a
browser:

    %s
    
You'll have to replace the last part of the URL with your own email address.
Once you see a web page confirming that your wallet is restarting, allow 2-5
minutes before attempting to access it.

If you have troubles with this mechanism, contact vlei-support@provenant.net.
"""

AUTO_SHUTDOWN_LOG = "/var/log/shutdown-if-inactive.log"


def configure_auto_shutdown():
    restart_url = os.path.expanduser(RESTART_URL)
    if not os.path.isfile(restart_url):
        print("Configuring auto shutdown behavior.")
        with open(restart_url, "wt") as f:
            if is_hosted_on_provenant_aws():
                restart_url = "https://start.wallet.provenant.net/youremail@your.org"
                os.system(f'sudo crontab /home/ubuntu/pcw/shutdown-if-inactive.crontab')
            else:
                restart_url = ""
            f.write(restart_url)
    else:
        with open(restart_url, "rt") as f:
            restart_url = f.read().strip()
    if not guest_mode_is_active():
        with TempColor(term.dim_white, MAINTENANCE_COLOR):
            advice = AUTO_SHUTDOWN_EXPLANATION % restart_url if restart_url else NO_AUTO_SHUTDOWN_EXPLANATION
            print(advice)


UPGRADER_PAT = re.compile(r'^\d+[.]py$')
UPGRADER_PATH = os.path.join(MY_FOLDER, "upgraders")


def _get_upgrader_files():
    upgraders = []
    for item in os.listdir(UPGRADER_PATH):
        if UPGRADER_PAT.match(item):
            upgraders.append(item)
    return sorted(upgraders, key=lambda x: int(x[:-3]))


def _get_done_file_path(upgrader_path):
    return upgrader_path[:-3] + '.done'


def _get_pending_upgraders():
    pending = []
    for u in _get_upgrader_files():
        u_path = os.path.join(UPGRADER_PATH, u)
        done_path = _get_done_file_path(u_path)
        if not os.path.isfile(done_path):
            pending.append(u_path)
    return pending


def _run_upgrader(u):
    done_file = _get_done_file_path(u)
    err_file = done_file[:-5] + '.err'
    cmd = f"python3 {u} >{done_file} 2>{err_file}"
    cout(f"python3 {u}\n")
    exit_code = os.system(cmd)
    if exit_code:
        if os.path.exists(done_file):
            os.remove(done_file)
        cout(f"Errors during upgrade. See {err_file} for details.\n")
    else:
        num = os.path.split(u)[1][:-3]
        cout(f"Successfully ran upgrader/{num}.\n")
        if os.path.exists(err_file):
            with open(err_file, "rt") as f:
                msg = f.read().strip() + "\n"
            os.remove(err_file)
            if msg:
                with TempColor(term.white, MAINTENANCE_COLOR):
                    cout(msg)
    return exit_code == 0


def run_upgrade_scripts():
    clean = None
    pending = _get_pending_upgraders()
    clean = True if pending else None
    for u in pending:
        if not _run_upgrader(u):
            print(f"Upgrade script {u} is failing. Troubleshoot with support.")
            clean = False
            break
    if clean:
        print("All upgrade scripts ran cleanly.")


WHATS_NEW_SEMAPHORE = os.path.expanduser("~/.whatsnew-hash")
WHATS_NEW_FILE = os.path.expanduser("~/pcw/whatsnew.md")


def whats_new_has_changed():
    old_hash = None
    if os.path.exists(WHATS_NEW_SEMAPHORE):
        with open(WHATS_NEW_SEMAPHORE, "rt") as f:
            old_hash = f.read().strip()
    md5 = hashlib.md5()
    with open(WHATS_NEW_FILE, "rb") as f:
        md5.update(f.read())
    new_hash = md5.hexdigest()
    if new_hash != old_hash:
        return new_hash


def mention_whats_new():
    new_hash = whats_new_has_changed()
    if new_hash:
        with open(WHATS_NEW_SEMAPHORE, "wt") as f:
            f.write(new_hash)
        with TempColor(term.white, MAINTENANCE_COLOR):
            cout("\033[00mThe wallet has new features. Run the \033[0;34mwhatsnew\033[0;37m command to learn more.\n\n")



GUESTFILE="/tmp/guest.txt"
EMAIL_REGEX = re.compile("^[a-z0-9.-]+@[a-z0-9-]+[.][a-z0-9-.]+$")


def enforce_guest_checkout():
    # Undo dimness of maintenance text.
    sys.stdout.write(term.normal)

    with TempColor(term.white, MAINTENANCE_COLOR):
        try:
            if os.path.isfile(GUESTFILE):
                with open(GUESTFILE, 'rt') as f:
                    email = f.read().strip().lower()
                print("This wallet is currently in use by a guest.")
                answer = get_email()
                if not answer:
                    return False
                # Undo dimness of maintenance text again.
                sys.stdout.write(term.normal)
                if email != answer:
                    print(term.red("""\
Someone else has this wallet checked out. Please try a different guest wallet,
or check back in an hour to see if this one frees up."""))
                    return False
                else:
                    print("Welcome back to your checked out guest wallet.")
            else:
                print("""
Welcome. You can use this guest wallet to do KERI experiments with low risk.
Feel free to create and connect AIDs, issue credentials, try various commands
with the KERI kli tool, and so forth. All operations use stage witnesses
rather than production ones. Any data you create is temporary.

Guest wallets are checked out for the duration of a single SSH session plus a
few minutes (so you can log back in quickly if you get disconnected).
""")
                print(term.red("TERMS OF USE") + """ -- If you continue to use this wallet, you agree that:
    
1. You'll only use the wallet for KERI experiments, not for hacking, random
downloads, DOS attacks, SSH tunnels, etc. You won't install new stuff or
break stuff. Provenant may monitor your behavior to hold you accountable.

2. We offer no warranties or guarantees, and make no commitment to provide
support. Use at your own risk. However, if something breaks or you have a
burning question, please email pcw-guest@provenant.net.

3. You may use the code on this machine ONLY on this machine, and only while
you are in the current SSH session. You may not copy it elsewhere.
""")
                print(term.red("""IF YOU DON'T AGREE, LOG OFF NOW. OTHERWISE, CHECK OUT THE WALLET BY
PROVIDING YOUR EMAIL ADDRESS AS THE RESPONSIBLE PARTY.
    """))
                email = get_email()
                if not email:
                    return False
                else:
                    # Undo dimness of maintenance text again.
                    sys.stdout.write(term.normal)
                    print(term.normal + term.white(f"\nThis guest wallet now checked out to {email}."))
                    print(term.white("To relinquish, run:\n  ") + term.blue("guest-checkin") + "\n")
                with open(GUESTFILE, "wt") as f:
                    f.write(email)
            return True
        except KeyboardInterrupt:
            return False


def get_email():
    i = 5
    while i > 0:
        email = ask("Your email?").strip().lower()
        if EMAIL_REGEX.match(email):
            return email
        else:
            print("Bad email address.")
            i -= 1
