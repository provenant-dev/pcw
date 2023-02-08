import os

bashrc = os.path.expanduser('~/.bashrc')
with open(bashrc, 'rt') as f:
    txt = f.read()

if "PCW_SHARE_S3_ACCESS_KEY_ID2" not in txt:
    from helpers import *

    for var in ['S3_ACCESS_KEY_ID', 'S3_SECRET_ACCESS_KEY', 'PCW_SHARE_S3_ACCESS_KEY_ID', 'PCW_SHARE_S3_ACCESS_KEY']:
        txt = cut_var(txt, var)

    p = get_fragment_of_auk()

    import zipfile

    with zipfile.ZipFile(os.path.join(PCW_FOLDER, '5-data.zip')) as myzip:
        with myzip.open('shellvarvals.txt', pwd=p) as shellvars:
            vars = [x.strip() for x in shellvars.read().decode('ASCII').split("\n")]

        txt = txt.rstrip() + f"""

# Used by share-via-s3 to access a public bucket. This is low security
# and low stakes, primarily used as a convenient transfer method.
export PCW_SHARE_S3_ACCESS_KEY_ID="{vars[0]}"
export PCW_SHARE_S3_ACCESS_KEY="{vars[1]}"
"""

    with open(bashrc, 'wt') as f:
        f.write(txt)

    warn("\033[00mYour environment variables have been updated.\n")
    warn("Please run \033[0;34msource ~/.bashrc\033[00m or log in again to activate the change.\n")