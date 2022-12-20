#! /bin/env python3

import os
import re

org_alias_pat = re.compile(r'^\s*export\s+QAR_AID_ALIAS\s*=([^\n]*)', re.M)
source_script = os.path.expanduser("~/xar/source.sh")

with open(source_script, 'rt') as f:
    txt = f.read()

m = org_alias_pat.search(txt)
if m:
    alias = m.group(1).strip()
    if alias[0] in ['"', "'"]:
        alias = alias[1:]
    if alias[-1] in ['"', "'"]:
        alias = alias[0:-1]
    print(f"Active alias is {alias}.")
else:
    print(f"No QAR_AID_ALIAS export found in {source_script}.")
    import sys
    sys.exit(1)