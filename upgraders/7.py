import os

if os.path.isdir(os.path.join(os.path.expanduser('~/'), 'keripy')):
    # Make sure wallet is using production branch of keripy.
    os.system('cd ~/keripy && git checkout production')