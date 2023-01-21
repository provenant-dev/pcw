#! /bin/env python3

import os
import sys

if len(sys.argv) != 1:
    print("list-aliases")
    sys.exit(1)

passcode = os.environ.get('TYPED_PASSCODE', None)
db_name = os.environ.get('WALLET_DB_NAME', None)
if passcode and db_name:
    os.system(f'kli list --name {db_name} --passcode "{passcode}"')
else:
    print('Wallet passcode is not in memory. Run "unlock" command first.')
    sys.exit(1)