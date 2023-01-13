#! /bin/env python3

import os
import re
import sys

if len(sys.argv) != 3 or sys.argv[1] in ["?", "-h", "--h", "--help", "-?"]:
    print("use-alias <alias> <regname>")
    sys.exit(1)

def var_pat(var):
    return re.compile(r'^\s*export\s+' + var + r'\s*=([^\n]*)', re.M)

def change_var(txt, pat, new_val):
    m = pat.search(txt)
    if m:
        txt = txt[0:m.start()] + new_val + txt[m.end():]
    else:
        txt += "\n" + new_val + "\n"
    return txt

def update_file(fname, alias, reg):
    os.system(f'cp {fname} {fname}.bak')
    with open(fname, 'rt') as f:
        txt = f.read()
    txt = change_var(txt, var_pat('QAR_AID_ALIAS'), f'export QAR_AID_ALIAS="{alias}"')
    txt = change_var(txt, var_pat('QAR_REG_NAME'), f'export QAR_REG_NAME="{reg}"')
    with open(fname, 'wt') as f:
        f.write(txt)
    print(f"Now acting as alias {alias} with registry {reg}.")

update_file(os.path.expanduser("~/xar/source.sh"), sys.argv[1], sys.argv[2])
