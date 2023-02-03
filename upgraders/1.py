from helpers import *

os.chdir(HOME_FOLDER)
salt_file = os.path.join(XAR_FOLDER, "salt")
salt_bak_file = os.path.join(HOME_FOLDER, '.salt.bak')
if os.path.isfile(salt_file):
    run_or_die(f"cp {salt_file} {salt_bak_file}")
folder = os.path.join(XAR_FOLDER, 'data')
temp_location = "~/was-xar-data"
if os.path.isdir(folder):
    items = [x for x in os.listdir(folder) if x != '.do_not_delete']
    if items:
        run_or_die(f"mv ~/xar/data {temp_location}")
    run_or_die(f"rm -rf ~/xar")
    run_or_die(f"git clone https://github.com/provenant-dev/xar.git")
    if items:
        run_or_die(f"cp -r {temp_location}/* ~/xar/data")
        run_or_die(f"rm -rf {temp_location}")
if os.path.isfile(salt_bak_file):
    run_or_die(f"mv {salt_bak_file} {salt_file}")