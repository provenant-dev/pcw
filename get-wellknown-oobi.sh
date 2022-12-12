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

done
a = {
    "urls": [
        "http://witness1.main.provenant.net:5631/oobi/BNwSX8dtJ_Q-jlSIcgaL9phC2qT-PwNy_z1p-QSFPGMg/controller?name=prmain-1",
        "http://witness2.main.provenant.net:5631/oobi/BK5BgSYAzXvkzZU03-8Fo_eWoVdvlwQexGavi205MKQN/controller?name=prmain-2",
        "http://witness3.main.provenant.net:5631/oobi/BIHIg-sMesHIzbLzl8r9hq4797WZ8yKBidIKUKPrmEAk/controller?name=prmain-3",
        "http://witness4.main.provenant.net:5631/oobi/BLBC0dK4vnEEMa3Gw_P9_rHow6BRmU5lIXUqxdbEKWKk/controller?name=prmain-4",
        "http://witness5.main.provenant.net:5631/oobi/BOCWZuhoRHL_HpySDk450Shz2CNf9N5XNWmumlzvDGJj/controller?name=prmain-5"    
    ],
    "aid": "ED88Jn6CnWpNbSYz6vp9DOSpJH2_Di5MSwWTf1l34JJm"
}    
with habbing.openHab(name="test", temp=True) as (hby, hab): print(hab.reply(route="/oobi/witness", data=a))
