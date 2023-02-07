from helpers import *
import sys
sys.path.append(PCW_folder)

from util import get_shell_variable

bashrc = os.path.join(HOME_FOLDER, '.bashrc')
with open(bashrc, 'rt') as f:
    txt = f.read()

val, exported, start, end = get_shell_variable("S3_SECRET_ACCESS_KEY", txt)
if end > 0:
    txt = txt[0:start].rstrip() + "\n" + txt[end:].lstrip()

val, exported, start, end = get_shell_variable("S3_ACCESS_KEY_ID", txt)
if end > 0:
    txt = txt[0:start].rstrip() + "\n" + txt[end:].lstrip()

txt = txt.rstrip() + """

# Used by share-via-s3 to access a public bucket. This is low security
# and low stakes, primarily used as a convenient transfer method.
export PCW_SHARE_S3_ACCESS_KEY_ID="AKIAY26NZEFT73QNUWGJ"
export PCW_SHARE_S3_ACCESS_KEY="/W6bv5C5hymUoqLc8s8EqLYcI5UMXHjQPuvSvLJx"
"""

with open(bashrc, 'wt') as f:
    f.write(txt)