import os
import re
import shutil
import sys
import time
import traceback

import blessings


LOG_FILE = os.path.expanduser("~/.maintain.log")
RESET_PROMPT = """\
Resetting state is destructive. It removes your history, all your AIDs,
and all your keys. All credentials you've received or issued become
unusable, and all multisigs where you are a participant lose your input.
It is basically like creating a brand new wallet. Type "yes" to confirm."""
RERUNNER = '.rerun'
ESC_SEQ_PAT = re.compile("(?:\007|\033)\\[[0-9;]+[Bm]")

log = open(LOG_FILE, 'at')
term = blessings.Terminal()


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


def fix_prompt(script):
    log.write("Fixing ")
    prompt_pat = re.compile(r'\s*PS1\s*=')
    lines = script.split('\n')
    new_lines = []
    for line in lines:
        if prompt_pat.match(line):
            line = line.replace('\\u@\\h', "${OWNER}\\047s wallet")
        new_lines.append(line)
    return '\n'.join(new_lines)


def run(cmd):
    exitcode = os.system(cmd + f" >{LOG_FILE} 2>&1")
    if exitcode:
        cout(term.bright_red + "System command exited with code %d. Command was:" + term.normal + "\n  %s\n" % (exitcode, cmd))
    return exitcode


def get_repo_name(url):
    return url[url.rfind('/') + 1:-4]


def refresh_repo(url):
    fetched_anything = True
    repo_name = get_repo_name(url)
    git_log = f".git-pull-{repo_name}.log"
    if os.path.isdir(repo_name):
        cout(f"Checking for {repo_name} updates.\n")
        run(f"cd {repo_name} && git pull >{git_log} 2>&1")
        with open(git_log, "rt") as f:
            result = f.read().strip()
        os.remove(git_log)
        fetched_anything = bool(result != "Already up to date.")
        log.write(result)
    else:
        cout(f"Installing {repo_name}.\n")
        run(f"git clone {url}")
    return fetched_anything


def get_variable(variable, script):
    var_pat = re.compile(r'^\s*' + variable + r'\s*=\s*"([^"]+)"\n', re.MULTILINE)
    m = var_pat.search(script)
    if m:
        return m.group(1)


def personalize():
    bashrc = ".bashrc"
    semaphore = bashrc + '-changed'
    backup_file(bashrc)
    with open(bashrc, 'rt') as f:
        script = f.read()
    owner = get_variable("OWNER", script)
    if not owner:
        owner = ask("What is your first and last name?")
        script = f'OWNER="{owner}"\n' + fix_prompt(script)

        with open(bashrc, 'wt') as f:
            f.write(script)
        run(f"touch {semaphore}")
    return owner


def time_since(log_file):
    now = time.time()
    if os.path.isfile(log_file):
        elapsed = now - os.stat(log_file).st_mtime
    else:
        elapsed = now
    return elapsed


def patch_os(cache_secs=86400):
    if time_since(log_file) > cache_secs:
        cout("Making sure your wallet OS is fully patched.\n")
        run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get update -y")
        run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y")
        run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y")


def guarantee_venv():
    if not os.path.isdir("keripy/venv"):
        cout("Creating venv for keripy.\n")
        os.chdir("keripy")
        try:
            run("python3 -m venv venv")
        finally:
            os.chdir(os.path.expanduser("~/"))


def patch_source(owner, source_to_patch):
    my_folder = os.path.abspath(os.path.dirname(__file__))
    with open(os.path.join(my_folder, 'source.sh'), "rt") as f:
        source_script = f.read()
    with open(source_to_patch, 'wt') as f:
        f.write(source_script.replace('QAR_ALIAS=""', f'QAR_ALIAS="{owner}"'))


def reset():
    log.close()
    temp_log_fname = "~/.log"
    os.system(f"mv {LOG_FILE} {temp_log_fname}")
    log = open(temp_log_fname, "wt")
    run(f"rm {DATA_FOLDER}/*")
    log.close()
    os.system(f"mv {temp_log_fname} {LOG_FILE}")
    globals()["log"] = open(LOG_FILE, "at")
    run("rm -rf ~/keripy ~/vlei-qvi ~/.keri")
    run("mv ~/.bashrc.bak ~/.bashrc")


def do_maintainance():
    os.chdir(os.path.expanduser("~/"))
    log.write("\n\n" + "-" * 60 + "\nMaintenance script launched " + time.asctime())
    cout("\n\n--- Doing wallet maintenance.\n")
    try:
        try:  # Inside this block, use dim color. Revert to normal text when block ends.
            cout(term.dim_yellow)
            if os.path.exists(RERUNNER):
                cout("Detected rerun flag; removing.\n")
                os.remove(RERUNNER)
            if len(sys.argv) == 2 and sys.argv[1] == '--reset':
                if ask(RESET_PROMPT).lower() != "yes":
                    cout("Abandoning request to reset.\n")
                else:
                    cout("Resetting state. Log out and log back in to begin again.\n")
                    reset()
            else:
                if refresh_repo("https://github.com/provenant-dev/pcw.git"):
                    cout("Wallet software updated. Requesting re-launch.\n")
                    run(f"touch {RERUNNER}")
                    # Give file buffers time to flush.
                    time.sleep(1)
                else:
                    owner = personalize()
                    patch_os()
                    refresh_repo("https://github.com/provenant-dev/keripy.git")
                    guarantee_venv()

                    source_to_patch = 'vlei-qvi/source.sh'
                    # Undo any active patch that we might have against source.sh.
                    # so git won't complain about merge conflicts or unstashed files.
                    restore_from_backup(source_to_patch)
                    refresh_repo("https://github.com/provenant-dev/vlei-qvi.git")
                    # (Re-)apply the patch.
                    backup_file(source_to_patch)
                    patch_source(owner, source_to_patch)
        finally:
            sys.stdout.write(term.normal)
        cout("--- Maintenance tasks succeeded.\n\n")
    except KeyboardInterrupt:
        cout(term.bright_red + "--- Exited script early. Run {__file__} --reset to reset." + term.normal + "\n\n")
        sys.exit(1)
    except:
        cout(term.red + "--- Failure:")
        cout(traceback.format_exc())
        cout("---" + term.normal + "\n\n")


if __name__ == '__main__':
   do_maintainance()

