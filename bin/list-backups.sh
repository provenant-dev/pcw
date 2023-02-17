#!/usr/bin/env python3
"""
  This script is used by Provenant's Command-line Wallet (PCW) to list the wallet backups from local(~/backups/) and S3


Usage:
  $ ./list-backups.sh
    > List backups from local & S3
"""
import os
import sys
import argparse

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from WalletRestoreManager import WalletRestoreManager



parser = argparse.ArgumentParser(description='Lists backup of the wallet')

if __name__ == '__main__':
  args = parser.parse_args()
  restore = WalletRestoreManager(args)
  restore.show_backup_list()
