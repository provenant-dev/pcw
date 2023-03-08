import os

# maintain.sh guarantees that these are installed in the virtual env, but
# we want to guarantee that they are also available if the virtual env
# never gets activated.
os.system('pip install blessings boto3 requests')