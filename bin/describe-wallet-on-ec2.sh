#!/usr/bin/env python3

import os
import sys
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import util

d = util.get_ec2_metadata()

def try_get(item, d):
    return d.get(item, "unknown")

account = try_get("accountId", d)
zone = try_get("availabilityZone", d)
ami = try_get("imageId", d)
instance = try_get("instanceId", d)

print(f"This is EC2 instance {instance}\n  from {ami}\n  on account {account}\n  at {zone}")