#!/usr/bin/env python3
"""
    This script is used by Provenant's Command-line Wallet (PCW) to upload or
      download a file via S3.
    You must have boto3 (the AWS lib for python) installed to run it.
    Uploaded files are stored in the bucket public-pcw-share.
    Uploaded files will be renamed to prevent spurious collisions (two wallets
      uploading a file with the same name at the same time). The name that's
      chosen is echoed to the screen and must be supplied as a command-line
      argument by remote parties who wish to download.
    Downloaded files will automatically be renamed back to their original name.
Usage:
    python s3_file_share.py upload --file ~/xar/data/le.json
       > echoes to the screen: "Uploading ~/xar/data/le.json to s3 as abc123xyz. Give the latter name to others for download."
    python s3_file_share.py download --pkg abc123xyz --file ~/xar/data/le.json

"""

import argparse
import os
import sys
import time
import warnings

import boto3

BUCKET_NAME = 'public-pcw-share'

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.environ['PCW_SHARE_S3_ACCESS_KEY_ID2'],
    aws_secret_access_key=os.environ['PCW_SHARE_S3_ACCESS_KEY2'],
    region_name="us-east-1"
)


def get_obj_name(file_path):
    timestamp = str(time.time())
    owner = os.environ.get('OWNER', "")
    org = os.environ.get('ORG', "")
    seed = f"{owner}@{org}@{timestamp}".encode('ASCII')

    import hashlib

    md5 = hashlib.md5()
    md5.update(seed)

    return md5.hexdigest()[:8]


def download_file(obj, file_path):
    s3.download_file(BUCKET_NAME, obj, file_path)
    print(f"Downloaded {file_path} from {obj} on s3.")


def upload_file(file_path):
    obj = get_obj_name(file_path)
    rel_path = os.path.relpath(file_path, os.getcwd())
    print(f"Uploading {rel_path} to s3 as {obj}. Give the latter name to others for download.")

    # For safety, wait 5s. This helps protect against cases where
    # the file is still being modified after it's initially written.
    time.sleep(5)

    s3.upload_file(file_path, BUCKET_NAME, obj)
    print("Upload complete.")

    # forcefully quit
    exit(0)


# This class is a simple replacement for pyinotify. The word "simple" is important.
# When we originally wrote this script, we actually used pyinotify. However, this turned
# out to be problematic. For one, pyinotify is an old library that is not maintained well.
# For another, it depends on kernel features that are sensitive to configuration and
# context (e.g., how many open file handles can be used by the current user). What we
# found was that lots of things could go wrong, and our rate of success was very low.
# We needed something simpler. That's what we have here. It doesn't react to events
# as quickly as inotify -- but it also has no dependencies, and it's much easier to
# debug and to achieve success.
def watch_file(path, timeout=30):
    print(f"Watching for {path} to become available.")
    while timeout > 0:
        if os.path.isfile(path):
            time.sleep(1.0)
            print(f"\nFile {path} is now available.")
            return True
        time.sleep(1.0)
        sys.stdout.write('.')
    return False


parser = argparse.ArgumentParser(description='Upload or download a file')
parser.add_argument('command', type=str, help='upload or download')
parser.add_argument('--file', type=str, required=True, help='path of uploaded/downloaded file')
parser.add_argument('--obj', type=str, help='identifier of object on S3 to download')
parser.add_argument('--now', action='store_true', default=False,
                    required=False, help='skip watching and upload immediately')


def main():
    args = parser.parse_args()

    if args.command == 'upload':

        if not args.file:
            print("Need --file <path of file before upload>.")
            exit(1)

        path = os.path.abspath(args.file)
        if not args.now:
            if not watch_file(path):
                print(f"Timed out before {path} became available.")
                exit(1)

        upload_file(path)

    elif args.command == 'download':
        if not args.obj:
            print("Need --obj <identifier for object on S3>.")
            exit(1)
        if not args.file:
            print("Need --file <path of file after download>.")
            exit(1)

        download_file(args.obj, args.file)

    else:
        print("Command not recognized")
        exit(1)


if __name__ == '__main__':
    main()
