import os
import re
import sys

UPGRADER_PAT = re.compile(r'^\d+[.].py$')
MY_FOLDER = os.path.dirname(os.path.abspath(__file__))


def get_upgrader_files():
    upgraders = []
    for item in os.path.listdir(MY_FOLDER):
        if UPGRADER_PAT.match(item):
            upgraders.append(item)
    return sorted(upgraders, key=lambda x: int(x[:-3]))


def get_done_file_path(upgrader_path):
    return upgrader_path[:-3] + '.done'


def get_pending_upgraders():
    pending = []
    for u in get_upgraders():
        u_path = os.path.join(MY_FOLDER, u)
        done_path = get_done_file_path(u)
        if not os.path.isfile(done_path):
            pending.append(u_path)


def run_upgrader(u):
    done_file = get_done_file_path(u)
    exit_code = os.system(f"python3 {u} >{done_file}")
    if exit_code:
        err_file = done_file[:-5] + '.err'
        os.rename(done_file, err_file)
        print(f"Errors during upgrade. See {err_file} for details.")
    else:
        num = os.path.split(u)[:-3]
        print(f"Successfully ran upgrader/{num}.")


if __name__ == '__main__':
    for u in get_pending_upgraders():
        if not run_upgrader(u):
            print("Upgrade script %s is failing. Troubleshoot with support.")
            sys.exit(1)