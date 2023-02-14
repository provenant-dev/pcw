#!/usr/bin/env python3
"""
  This script is used by Provenant's Command-line Wallet (PCW) to list the wallet backups from local(~/backups/) and S3

Requirements:
  - pip3 install requests
  - pip3 install boto3

Usage:
  $ ./list-backups.sh
    > List backups from local & S3
"""
import os
import argparse
import requests
import boto3
from boto3.session import Session


BUCKET_NAME = 'pcw-backups'

AWS_ACCESS_KEY_ID=os.environ['PCW_SHARE_S3_ACCESS_KEY_ID']
AWS_ACCESS_KEY=os.environ['PCW_SHARE_S3_ACCESS_KEY']
AWS_REGION_NAME="us-east-1"


class WalletRestoreManager:
  def __init__(self, args):
    self.args = args
    self.backup_list = []
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


  def __list_local_backup(self):
    res = os.listdir(os.path.expanduser('~') + '/backups/')
    for i in res:
      self.backup_list.append(i+'.local')


  def __list_s3_backup(self):
    session = Session(aws_access_key_id=AWS_ACCESS_KEY_ID,aws_secret_access_key=AWS_ACCESS_KEY, region_name=AWS_REGION_NAME)
    s3 = session.resource('s3')
    bucket = s3.Bucket(BUCKET_NAME)
    for s3_file in bucket.objects.filter(Prefix = self.owner + "/"):
      if(s3_file.key[len(self.owner)+1:] + ".local" not in self.backup_list):
        self.backup_list.append(s3_file.key[len(self.owner)+1:])
    

  def __list_backup(self):
    self.__list_local_backup()
    self.__list_s3_backup()
    self.backup_list.sort(reverse=True) # most recent first order


  def show_backup_list(self):
    self.__get_owner_name()
    self.__list_backup()
    index = 0
    print("Wallet backups are listed below: ")
    for i in self.backup_list:
      if(i.endswith('.local')):
        print(f"{index}: {i[0:len(i)-6]} (Local)")
      else:
        print(f"{index}: {i} (Remote)")
      index+=1



parser = argparse.ArgumentParser(description='Lists backup of the wallet')

if __name__ == '__main__':
  args = parser.parse_args()
  restore = WalletRestoreManager(args)
  restore.show_backup_list()
