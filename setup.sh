#!/usr/bin/env python3

import os
import shutil
import re
import time
import sys


def ask(question):
    return input('  ' + question + ' ').strip()


def backup_file(fname, once_only=True):
    backup_name = fname + '.bak'
    if not os.path.isfile(backup_name) or not once_only:
        shutil.copyfile(fname, backup_name)


def restore_from_backup(fname):
    backup_name = fname + '.bak'
    if os.path.isfile(backup_name):
        shutil.copyfile(backup_name, fname)
        return True


def fix_prompt(script):
    prompt_pat = re.compile(r'\s*PS1\s*=')
    lines = script.split('\n')
    new_lines = []
    for line in lines:
        if prompt_pat.match(line):
            line = line.replace('\\u@\\h', "${OWNER}\\047s wallet")
        new_lines.append(line)
    return '\n'.join(new_lines)


def run(cmd):
    exitcode = os.system(cmd)
    if exitcode:
        print("\nSystem command exited with code %d. Command was:\n  %s" % (exitcode, cmd))
    return exitcode


def get_repo_name(url):
    return url[url.rfind('/') + 1:-4]


def get_log_path_for_repo(url):
    return get_repo_name(url) + '.log'


def refresh_repo(url):
    fetched_anything = True
    repo_name = get_repo_name(url)
    log_path = get_log_path_for_repo(url)
    if os.path.isdir(repo_name):
        print(f"\nChecking for {repo_name} updates.\n")
        run(f"cd {repo_name} && git pull >~/{log_path} 2>&1")
        with open(log_path, "rt") as f:
            result = f.read().strip()
        fetched_anything = bool(result != "Already up to date.")
    else:
        print(f"\nInstalling {repo_name}.\n")
        run(f"git clone {url} >~/{log_path} 2>&1")
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
        os.system('touch {semaphore}')
    return owner


def time_since(log_file):
    now = time.time()
    if os.path.isfile(log_file):
        elapsed = now - os.stat(log_file).st_mtime
    else:
        elapsed = now
    print(f"elapsed for {log_file} = {elapsed}")
    return elapsed


def patch_os(cache_secs=86400):
    log_file = "apt.log"
    if time_since(log_file) > cache_secs:
        print("Making sure your wallet OS is fully patched.")
        run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get update -y >~/{log_file} 2>&1")
        run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >>~/{log_file} 2>&1")
        run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >>~/{log_file} 2>&1")


def guarantee_venv():
    if not os.path.isdir("keripy/venv"):
        print("Creating venv for keripy.")
        os.chdir("keripy")
        try:
            os.system("python3 -m venv venv >/dev/null 2>&1")
        finally:
            os.chdir(os.path.expanduser("~/"))


if __name__ == '__main__':
    print("\n\n\n---------- starting setup")
    sys.stdout.flush()
    rerunner = '.rerun'
    os.chdir(os.path.expanduser("~/"))
    try:
        if os.path.exists(rerunner):
            print("Detected rerunner; removing.")
            os.remove(rerunner)
        if len(sys.argv) == 2 and sys.arg[1] == '--clean':
            os.system('rm -rf keripy vlei-qvi && mv .bashrc.bak .bashrc; rm *.log')
        else:
            if refresh_repo("https://github.com/provenant-dev/pcw.git"):
                print("Wallet software updated. Requesting re-launch.")
                os.system(f"touch {rerunner}")
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
                my_folder = os.path.abspath(os.path.dirname(__file__))
                shutil.copyfile(os.path.join(my_folder, 'source.sh'), source_to_patch)
        print("Exiting with success.")
        sys.exit(0)
    except KeyboardInterrupt:
        print("\nExited script early. Run with --clean to start fresh.")
        sys.exit(1)
