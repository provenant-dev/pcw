#!/usr/bin/env python3
"""
    This script is used by Provenant's Command-line Wallet (PCW) to upload or
      download a file via S3.
    You must have boto (the AWS lib for python) installed to run it.
    Uploaded files are stored in the bucket pcw-share.
    Uploaded files will be renamed to prevent spurious collisions (two wallets
      uploading a file with the same name at the same time). The name that's
      chosen is echoed to the screen and must be supplied as a command-line
      argument by remote parties who wish to download.
    Downloaded files will be renamed back to their original name.
Usage:
    python s3_file_share.py upload --file ~/xar/data/le.json
       > echoes to the screen: "Uploading le.json. Tell others to download package abc123xyz.
    python s3_file_share.py download --pkg abc123xyz --file ~/xar/data/le.json

"""

import argparse
import os
import sys
import time
import warnings

import boto3
import pyinotify

warnings.filterwarnings("ignore", category=DeprecationWarning)

BUCKET_NAME = 'public-join-legal-credential'
TIMEOUT = 30  # seconds

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.environ['S3_ACCESS_KEY_ID'],
    aws_secret_access_key=os.environ['S3_SECRET_ACCESS_KEY'],
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
    print(f"Uploading {rel_path} to s3 as {obj}. Give the latter name to collaborators for download.")

    # For safety, wait 5s. This helps protect against cases where
    # the file is still being modified after it's initially written.
    time.sleep(5)

    s3.upload_file(file_path, BUCKET_NAME, obj)
    print("Upload complete.")

    # forcefully quit
    exit(0)


# noinspection PyPep8Naming,PyMethodMayBeStatic
class EventHandler(pyinotify.ProcessEvent):
    def __init__(self, file_name):
        print("Watching for file: {}".format(file_name))

        super(EventHandler, self).__init__()
        self.file_name = file_name

    def process_IN_MODIFY(self, event):
        upload_file(event.pathname)


class CustomThreadedNotifier(pyinotify.ThreadedNotifier):
    def __init__(self, watch_manager, default_proc_fun=None, read_freq=1):
        super(CustomThreadedNotifier, self).__init__(watch_manager, default_proc_fun, read_freq)
        self.start_time = time.time()

    def loop(self):
        while not self._stop_event.isSet():

            self.process_events()
            ref_time = time.time()

            if self.check_events():
                self._sleep(ref_time)
                self.read_events()

            if time.time() - self.start_time > TIMEOUT:
                print("Timeout reached")
                break


def watch_dir(path, file_name):
    wm = pyinotify.WatchManager()
    notifier = CustomThreadedNotifier(wm, EventHandler(file_name=file_name))
    notifier.start()

    # watch for all events in the path
    wm.add_watch(path, pyinotify.ALL_EVENTS)

    # wait for the thread to finish
    notifier.join(TIMEOUT)


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

        if args.now:
            upload_file(args.file)
        else:
            folder, file = os.path.split(args.file)
            watch_dir(folder, file)

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