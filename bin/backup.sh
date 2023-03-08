#!/usr/bin/env python3
"""
  This script is used by Provenant's Command-line Wallet (PCW) to backup the wallet into `~/backups/` (local) directory and S3(remote)

Requirements:
  - pip3 install requests
  - pip3 install boto3

Usage:
  $ ./backup.sh --passcode <PASSWORD-FOR-ZIP>
    > Zip files & stores in `~/backups/` & S3

Backup Files:
  ~/.keri (folder)
  ~/xar/salt (file)
  ~/xar/data (folder)
  ~/.passcode-hash
  ~/.bashrc
  ~/.bash_history
"""

import os
import sys
import argparse
import requests
import subprocess
from datetime import datetime
import boto3

BUCKET_NAME = 'pcw-backups'

AWS_ACCESS_KEY_ID=os.environ['PCW_SHARE_S3_ACCESS_KEY_ID']
AWS_ACCESS_KEY=os.environ['PCW_SHARE_S3_ACCESS_KEY']
AWS_REGION_NAME="us-east-1"

class WalletBackupManager:

  def __init__(self, args):
    self.args = args
    self.output_file_name = ''
    self.output_file_path = ''
    self.password = ''
    self.owner = ''


  def __collect_owner_from_tag(self, instance_id):
    ec2 = boto3.client(
      "ec2",
      aws_access_key_id=AWS_ACCESS_KEY_ID,
      aws_secret_access_key=AWS_ACCESS_KEY,
      region_name=AWS_REGION_NAME
    )
    response = ec2.describe_tags(
      DryRun=False, Filters=[{"Name": "resource-id", "Values": [instance_id]}]
    )
    for i in response['Tags']:
      if(i['Key']=='owner'):
        self.owner = i['Value']
        return i['Value']
    raise Exception("Owner Tag not found!")
  

  def __get_owner_name(self):
    res = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
    if res and res.text:
      return self.__collect_owner_from_tag(res.text)
    else:
      raise Exception('Instance ID not found!')


  def __collect_password(self, password = None):
    if password or os.getenv('TYPED_PASSCODE'):
      self.password = password or os.getenv('TYPED_PASSCODE')
    else:
      while True:
        password = input("Enter Password: ")
        retyped_password = input("Re-Enter Password: ")
        if(password == retyped_password):
          break
        print("Wrong confirmation password. Please try again.")
      
      self.password = password


  def __generate_output_file_name(self):
    owner = self.__get_owner_name()
    x = datetime.utcnow()
    self.output_file_name = owner + x.strftime("-%Y-%m-%d@%H%MZ.zip")
    self.output_file_path = os.path.expanduser('~') + "/backups/" + self.output_file_name


  def __zipping_file(self):
    zip_content="~/.keri/ ~/xar/salt ~/xar/data/ ~/.passcode-hash ~/.bashrc ~/.bash_history"
    zip_command = "zip -r --password " + self.password + " ~/backups/" + self.output_file_name + " " + zip_content

    res = subprocess.run("mkdir -p ~/backups", capture_output=True, text=True, shell=True)
    if res.returncode != 0:
      raise Exception(f"Error running mkdir | {res.stdout}")
    res = subprocess.run(zip_command, capture_output=True, text=True, shell=True)
    if res.returncode != 0:
      raise Exception(f"Error while zipping | {res.stdout}")


  def __upload_zip_to_s3(self):
    s3 = boto3.client(
      "s3",
      aws_access_key_id=AWS_ACCESS_KEY_ID,
      aws_secret_access_key=AWS_ACCESS_KEY,
      region_name=AWS_REGION_NAME
    )
    s3.upload_file(self.output_file_path, BUCKET_NAME, self.owner + "/" + self.output_file_name)
    print("Upload complete.")
    

  def create_backup(self):
    try:
      self.__collect_password(self.args.passcode)
      self.__generate_output_file_name()
      self.__zipping_file()
      self.__upload_zip_to_s3()
    except Exception as e:
      print(e)
      sys.exit()



parser = argparse.ArgumentParser(description='Backup the wallet')
parser.add_argument('--passcode', type=str, required=False, help='Set passcode for your backup file')


if __name__ == '__main__':
  args = parser.parse_args()
  backup = WalletBackupManager(args)
  backup.create_backup()
