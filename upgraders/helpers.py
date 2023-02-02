import os
import shutil
import sys

MY_FOLDER = os.path.dirname(os.path.abspath(__file__))
HOME_FOLDER = os.path.expanduser("~/")
XAR_FOLDER = os.path.join(HOME_FOLDER, "xar")
KERIPY_FOLDER = os.path.join(HOME_FOLDER, "keripy")
PCW_FOLDER = os.path.join(HOME_FOLDER, "pcw")


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