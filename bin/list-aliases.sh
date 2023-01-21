#! /bin/env python3

import os
import sys

if len(sys.argv) != 1:
    print("list-aliases")
    sys.exit(1)

passcode = os.environ.get('TYPED_PASSCODE', None)
if passcode:
    os.system(f'kli list --name XAR --passcode "{passcode}"')
else:
    print('Wallet passcode is not in memory. Run "unlock" command first.')
    sys.exit(1)