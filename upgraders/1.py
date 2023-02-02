from helpers import *

os.chdir(HOME_FOLDER)
folder = os.path.join(XAR_FOLDER, 'data')
temp_location = "~/was-xar-data"
if os.path.isdir(folder):
    run_or_die(f"mv ~/xar/data {temp_location}")
    run_or_die(f"rm -rf ~/xar")
    run_or_die(f"git clone https://github.com/provenant-dev/vlei-qvi.git")
    run_or_die(f"mv {temp_location} ~/xar/data")
