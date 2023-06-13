#! /usr/bin/env python3

import json

from keri.app import habbing
from keri.core import coring

# Modify the JSON fragment below. The urls array should have all the witnesses
# for the AID in question, and the AID field should have just the value of the
# AID of interest.
# When the script runs, copy JUST the JSON portion of the output (trimming off
# stuff at the front and the signature at the end. What you copy will start with
# a { and end with two }}s. This is what you save as index.json in the
# .well-known/keri/oobi/<aid> folder on the website.

a = {
    "urls": [
      "http://witness1.main.provenant.net:5631/oobi/ED88Jn6CnWpNbSYz6vp9DOSpJH2_Di5MSwWTf1l34JJm/witness",
      "http://witness2.main.provenant.net:5631/oobi/ED88Jn6CnWpNbSYz6vp9DOSpJH2_Di5MSwWTf1l34JJm/witness",
      "http://witness3.main.provenant.net:5631/oobi/ED88Jn6CnWpNbSYz6vp9DOSpJH2_Di5MSwWTf1l34JJm/witness",
      "http://witness4.main.provenant.net:5631/oobi/ED88Jn6CnWpNbSYz6vp9DOSpJH2_Di5MSwWTf1l34JJm/witness",
      "http://witness5.main.provenant.net:5631/oobi/ED88Jn6CnWpNbSYz6vp9DOSpJH2_Di5MSwWTf1l34JJm/witness"
    ],
    "aid": "ED88Jn6CnWpNbSYz6vp9DOSpJH2_Di5MSwWTf1l34JJm"
}
with habbing.openHab(name="test", temp=True) as (hby, hab): print(hab.reply(route="/oobi/witness", data=a))
