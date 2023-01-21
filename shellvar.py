import os
import sys
from util import set_or_update_shell_variable

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("shellvar VARIABLE SCRIPT VALUE [export]")
        sys.exit(1)
        if len(sys.argv) > 4:
            export = bool(sys.argv[4].lower()[0] == 'e')
        else:
            export = False
    script = os.path.expanduser(sys.argv[2])
    if not os.path.isfile(script):
        print(f"Script {script} does not exist.")
        sys.exit(1)
    with open(script, "rt") as f:
        txt = f.read()
    new_txt = set_or_update_shell_variable(sys.argv[1], script, sys.argv[3], export)
    os.system(f"cp {fname} {fname}.bak")
    with open(script, "wt") as f:
        f.write(new_txt)
