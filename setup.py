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
            line = line.replace('\\u@\\h', "${OWNER}'s wallet")
        new_lines.append(line)
    return '\n'.join(new_lines)


def run(cmd):
    print(cmd)
    return os.system(cmd)


def refresh_repo(url):
    repo_name = url[url.rfind('/') + 1:-4]
    if os.path.isdir(repo_name):
        run(f"cd {repo_name} && git pull")
    else:
        run(f"git clone {url}")


def get_variable(variable, script):
    var_pat = re.compile(r'^\s*' + variable + r'\s*=\s*([a-zA-Z0-9].*?)\n', re.MULTILINE)
    m = var_pat.search(txt)
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
        script = f"OWNER={owner}\n" + fix_prompt(script)
        with open(bashrc, 'wt') as f:
            f.write(script)
        print("Please run the following command to refresh your wallet config:\n  source .bashrc")


if __name__ == '__main__':
    os.chdir(os.path.expanduser("~/"))
    try:
        personalize()
    except KeyboardInterrupt:
        print("\nExited script early. Run with --clean to start fresh.")