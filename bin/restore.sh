#!/usr/bin/env python3
"""
  This script is used by Provenant's Command-line Wallet (PCW) to restore the wallet backups from local(~/backups/) and S3


Usage:
  $ ./restore.sh
    > Restore backups from local & S3
"""
import os
import sys
import argparse


sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from WalletRestoreManager import WalletRestoreManager



parser = argparse.ArgumentParser(description='Restore backup of the wallet')
parser.add_argument('--passcode', type=str, required=False, help='Passcode for your backup')


if __name__ == '__main__':
  args = parser.parse_args()
  restore = WalletRestoreManager(args)
  restore.restore_backup()
