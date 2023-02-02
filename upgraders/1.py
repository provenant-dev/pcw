import os

from helpers import *

ugly_patched_files = [
    'scripts/source.sh',
    'scripts/qar-local-incept.json',
    'scripts/keri/cf/qar-config.json']

for item in ugly_patched_files:
    reset_from_git('xar', item)
