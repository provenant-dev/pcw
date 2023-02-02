from helpers import *

bashrc = os.path.join(HOME_FOLDER, '.bashrc')
with open(bashrc, 'rt') as f:
    txt = f.read()

rewrite = False
if 'S3_SECRET_ACCESS_KEY' not in txt:
    txt = txt.rstrip() + '\nexport S3_SECRET_ACCESS_KEY="W6bv5C5hymUoqLc8s8EqLYcI5UMXHjQPuvSvLJx"\n'
    rewrite = True

if 'S3_ACCESS_KEY_ID' not in txt:
    txt = txt.rstrip() + '\nexport S3_ACCESS_KEY_ID="AKIAY26NZEFT73QNUWGJ"\n'
    rewrite = True

if rewrite:
    with open(bashrc, 'wt') as f:
        f.write(txt)

