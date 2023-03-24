#!/usr/bin/env python3
"""
  This script is used by Provenant's Command-line Wallet (PCW) for backup restore management

Requirements:
  - pip3 install requests
  - pip3 install boto3
  - sudo apt install zip

"""
import os
import subprocess
import requests
import boto3
from boto3.session import Session


BUCKET_NAME = 'pcw-backups'

AWS_ACCESS_KEY_ID=os.environ['PCW_SHARE_S3_ACCESS_KEY_ID2']
AWS_ACCESS_KEY=os.environ['PCW_SHARE_S3_ACCESS_KEY2']
AWS_REGION_NAME="us-east-1"


class WalletRestoreManager:
  def __init__(self, args):
    self.args = args
    self.backup_list = []
    self.local_backup_path = os.path.expanduser('~') + "/backups/"
    self.selected_backup = None
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
    

  def __show_backup_list(self):
    index = 0
    print("Wallet backups are listed below: ")
    for i in self.backup_list:
      if(i.endswith('.local')):
        print(f"{index}: {i[0:len(i)-6]} (Local)")
      else:
        print(f"{index}: {i} (Remote)")
      index+=1
    
  
  def __select_backup(self):
    try:
      self.selected_backup = int(input("Please Enter the Serial no of backup you want to restore: "))
      if self.selected_backup<0 and self.selected_backup>=len(self.backup_list):
        print("Invalid Input")
        exit()
    except Exception as err:
      print(err)
      exit()

  def __restore_warning(self):
    inp = input("WARNING: This restore process is destructive because it might overwrite some state that the user cares about. Are you sure you want to continue? (yes/no) ")
    if(inp!='yes'):
      exit("Exiting")


  def __download_backup_from_s3(self):
    obj_name = self.backup_list[self.selected_backup]
    if obj_name.endswith('.local'):
      return
    s3 = boto3.client(
      's3',
      aws_access_key_id=AWS_ACCESS_KEY_ID,
      aws_secret_access_key=AWS_ACCESS_KEY,
      region_name=AWS_REGION_NAME
    )
    with open(self.local_backup_path + obj_name, 'wb') as f:
      s3.download_fileobj(BUCKET_NAME, self.owner + "/" + obj_name, f)
    print("Downloaded From S3")
    

  def __collect_password(self, password = None):
    if password or os.getenv('TYPED_PASSCODE'):
      self.password = password or os.getenv('TYPED_PASSCODE')
    else:
      self.password = input("Enter Password: ")


  def __unzip_backup(self):
    self.__collect_password()
    file = self.backup_list[self.selected_backup]
    if(file.endswith('.local')):
      file = file[0:len(file)-6]
    command = "unzip -P " + self.password + " -o -d / " + self.local_backup_path + file
    res = subprocess.run(command, capture_output=True, text=True, shell=True)

    if res.returncode != 0:
      raise Exception(f"Error while unzipping: {res.stdout}")
    
    print("\nRestore Report:\n")
    print(res.stdout)
    

  def show_backup_list(self):
    try:
      self.__get_owner_name()
      self.__list_local_backup()
      self.__list_s3_backup()
      self.backup_list.sort(reverse=True) # most recent first order
      self.__show_backup_list()
    except Exception as e:
      print(e)
      exit()


  def restore_backup(self):
    try:
      self.show_backup_list()
      self.__select_backup()
      self.__restore_warning()
      self.__download_backup_from_s3()
      self.__unzip_backup()
    except Exception as e:
      print(e)
      exit()
    


#### For Testing
# parser = argparse.ArgumentParser(description='Restore backup of the wallet')
# parser.add_argument('--passcode', type=str, required=False, help='Passcode for your backup')


# if __name__ == '__main__':
#   args = parser.parse_args()
#   restore = WalletRestoreManager(args)
#   restore.restore_backup()

