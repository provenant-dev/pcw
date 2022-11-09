#!/usr/bin/env python3

import os
import shutil
import re
import time


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
    if os.path.isdir(repo_name):
        if time.time() - last_run(log_file) > cache_secs:
            print(f"\nChecking for {repo_name} updates.\n")
            run(f"cd {repo_name} && git pull >~/{log_file}")
            with open(log_file, "rt") as f:
                result = f.read().strip()
            fetched_anything = bool(result != "Already up to date.")
    else:
        print(f"\nInstalling {repo_name}.\n")
        run(f"git clone {url} >~/{log_file}")
    return fetched_anything


def get_variable(variable, script):
    var_pat = re.compile(r'^\s*' + variable + r'\s*=\s*"([^"]+)"\n', re.MULTILINE)
    m = var_pat.search(script)
    if m:
        return m.group(1)


def personalize():
    bashrc = ".bashrc"
    backup_file(bashrc)
    with open(bashrc, 'rt') as f:
        script = f.read()
    owner = get_variable("OWNER", script)
    if not owner:
        owner = ask("What is your first and last name?")
        script = f'OWNER="{owner}"\n' + fix_prompt(script)
        with open(bashrc, 'wt') as f:
            f.write(script)
        print("\nPlease run the following command to refresh your wallet config:\n  source ~/.bashrc")
    return owner


def last_run(log_file):
    if os.path.isfile(log_file):
        return os.stat(log_file).st_mtime
    return 0


def patch_os(cache_secs=86400):
    log_file = "apt.log"
    if time.time() - last_run(log_file) < cache_secs:
        return
    print("Making sure your wallet OS is fully patched.")
    time.sleep(5)
    run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get update -y >~/{log_file}")
    run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >>~/{log_file}")
    run(f"sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >>~/{log_file}")


if __name__ == '__main__':
    my_folder = os.path.abspath(os.path.dirname(__file__))
    os.chdir(os.path.expanduser("~/"))
    try:
        if refresh_repo("https://github.com/provenant-dev/pcw.git"):
            print("Wallet software was updated. Please log off by typing 'exit' and then log back in.")
        else:
            owner = personalize()
            patch_os()
            refresh_repo("https://github.com/provenant-dev/keripy.git")
            source_to_patch = 'vlei-qvi/source.sh'
            first_patch = not restore_from_backup(source_to_patch)
            refresh_repo("https://github.com/provenant-dev/vlei-qvi.git")
            backup_file(source_to_patch)
            if first_patch:
                print("Patching source.sh")
            shutil.copyfile(os.path.join(my_folder, 'source.sh'), 'vlei-qvi/source.sh')
            print("""
Next command to run:
    source keripy/venv/bin/activate""")
    except KeyboardInterrupt:
        print("\nExited script early. Run with --clean to start fresh.")
