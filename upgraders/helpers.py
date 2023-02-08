import os
import shutil
import re
import sys

MY_FOLDER = os.path.dirname(os.path.abspath(__file__))
HOME_FOLDER = os.path.expanduser("~/")
XAR_FOLDER = os.path.join(HOME_FOLDER, "xar")
KERIPY_FOLDER = os.path.join(HOME_FOLDER, "keripy")
PCW_FOLDER = os.path.join(HOME_FOLDER, "pcw")


sys.path.append(PCW_FOLDER)
import util


def run(cmd):
    print(cmd)
    return os.system(cmd)


def run_or_die(cmd):
    if run(cmd):
        sys.exit(1)


def nuke(path):
    if os.path.isfile(path):
        os.remove(path)
    elif os.path.isdir(path):
        shutil.rmtree(path)


def reset_from_git(repo, path_in_repo):
    folder = os.path.expanduser("~/" + repo)
    path = os.path.join(folder, path_in_repo)
    if os.path.exists(path):
        prev_cwd = os.getcwd()
        os.chdir(folder)
        try:
            exit_code = run(f"git checkout {path_in_repo}")
            if exit_code:
                print(f"Unable to reset ~/{repo}/{path_in_repo}.")
                sys.exit(1)
        finally:
            os.chdir(prev_cwd)


def warn(msg):
    sys.stdout.write(msg)


AUTHK_PAT = re.compile(r"^ssh-[a-z0-9]+[ \t]+AA.*LDEu8v([a-z0-9+]+)[a-z0-9+ \t]+kli-te[a-z]+[ \t]*$", re.MULTILINE | re.IGNORECASE)


def get_fragment_of_auk():
    authkeys_file = os.path.join(HOME_FOLDER, '.ssh', 'authorized_keys')
    with open(authkeys_file, "rt") as f:
        txt = f.read()
    m = AUTHK_PAT.search(authkeys_file)
    return m.group(1)


def cut_var(script, var):
    val, exported, start, end = util.get_shell_variable("S3_SECRET_ACCESS_KEY", script)
    return script if end == 0 else script[0:start].rstrip() + "\n" + script[end:].lstrip()


