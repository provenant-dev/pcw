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


def refresh_repo(url):
    fetched_anything = True
    cache_secs = 8 * 60 * 60
    repo_name = url[url.rfind('/') + 1:-4]
    log_file = repo_name + '.log'
    if os.path.exists(log_file):
        os.remove(log_file)
    if os.path.isdir(repo_name):
        if time.time() - last_run(log_file) > cache_secs:
            print(f"\nChecking for {repo_name} updates.\n")
            run(f"cd {repo_name} && git pull >~/{log_file} 2>&1")
            with open(log_file, "rt") as f:
                result = f.read().strip()
            fetched_anything = bool(result != "Already up to date.")
    else:
        print(f"\nInstalling {repo_name}.\n")
        run(f"git clone {url} >~/{log_file} 2>&1")
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


def last_run(log_file):
    if os.path.isfile(log_file):
        return os.stat(log_file).st_mtime
    return 0


def patch_os(cache_secs=86400):
    log_file = "apt.log"
    if os.path.exists(log_file):
        os.remove(log_file)
    if time.time() - last_run(log_file) < cache_secs:
        return
    print("Making sure your wallet OS is fully patched.")
    time.sleep(5)
    run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get update -y >~/{log_file} 2>&1")
    run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >>~/{log_file} 2>&1")
    run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >>~/{log_file} 2>&1")


def guarantee_venv():
    if not os.path.isdir("keripy/venv"):
        os.chdir("keripy")
        try:
            os.system("python3 -m venv venv")
        finally:
            os.chdir(os.path.expanduser("~/"))


if __name__ == '__main__':
    my_folder = os.path.abspath(os.path.dirname(__file__))
    os.chdir(os.path.expanduser("~/"))
    try:
        if len(sys.argv) == 2 and sys.arg[1] == '--clean':
            os.system('rm -rf keripy vlei-qvi && mv .bashrc.bak .bashrc; rm *.log')
        else:
            if refresh_repo("https://github.com/provenant-dev/pcw.git"):
                print("Wallet software was updated. Please log off by typing 'exit' and then log back in.")
                sys.exit(1)
            else:
                owner = personalize()
                patch_os()
                refresh_repo("https://github.com/provenant-dev/keripy.git")
                guarantee_venv()
                source_to_patch = 'vlei-qvi/source.sh'
                first_patch = not restore_from_backup(source_to_patch)
                refresh_repo("https://github.com/provenant-dev/vlei-qvi.git")
                backup_file(source_to_patch)
                if first_patch:
                    print("Patching source.sh")
                shutil.copyfile(os.path.join(my_folder, 'source.sh'), 'vlei-qvi/source.sh')
    except KeyboardInterrupt:
        print("\nExited script early. Run with --clean to start fresh.")
        sys.exit(1)
