import os

# Make sure wallet is using production branch of keripy.
if os.path.isdir(os.path.expanduser("~/keripy")):
    os.system('cd ~/keripy && git checkout production')