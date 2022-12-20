#! /bin/env python3

import sys

if len(sys.argv) != 2 or sys.argv[1] in ["?", "-h", "--h", "--help", "-?"]:
    print("use-alias <alias>")
    sys.exit(1)

alias = sys.argv[1]
new_export = f'export QAR_AID_ALIAS="{alias}"'

import os
import re

org_alias_pat = re.compile(r'^\s*export\s+QAR_AID_ALIAS\s*=([^\n]*)', re.M)
source_script = os.path.expanduser("~/xar/source.sh")

with open(source_script, 'rt') as f:
    txt = f.read()

m = org_alias_pat.search(txt)
if m:
    txt = txt[0:m.start()] + new_export + txt[m.end():]
else:
    txt += "\n" + new_export + "\n"

with open(source_script, 'wt') as f:
    f.write(txt)

print(f"Active alias is now {alias}.")