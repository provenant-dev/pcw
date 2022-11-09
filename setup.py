import os
import shutil
import re


def ask(question):
    return input('  ' + question + ' ').strip()


def backup_file(fname, once_only=True):
    backup_name = fname + '.bak'
    if not os.path.isfile(backup_name) or not once_only:
        shutil.copyfile(fname, backup_name)


def restore_from_backup(fname):
    backup_name = fname + '.bak'
    shutil.copyfile(backup_name, fname)


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
    repo_name = url[url.rfind('/') + 1:-4]
    if os.path.isdir(repo_name):
        print(f"\nChecking for {repo_name} updates.\n")
        run(f"cd {repo_name} && git pull")
    else:
        print(f"\nInstalling {repo_name}.\n")
        run(f"git clone {url}")


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


def patch_os():
    print("""
Making sure your wallet OS is fully patched. This is a security best practice.
If you're asked to select services to restart, accept defaults and choose OK.

""")
    run("sleep 10 && sudo apt update && sudo apt upgrade")


if __name__ == '__main__':
    os.chdir(os.path.expanduser("~/"))
    try:
        personalize()
        patch_os()
        refresh_repo("https://github.com/provenant-dev/keripy.git")
        refresh_repo("https://github.com/provenant-dev/vlei-qvi.git")
    except KeyboardInterrupt:
        print("\nExited script early. Run with --clean to start fresh.")
