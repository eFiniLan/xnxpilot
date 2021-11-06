#!/usr/bin/env python3
import os
import subprocess

if __name__ == "__main__":

  if os.path.isfile("/EON"):
    language = subprocess.check_output(["getprop", "persist.sys.locale"], encoding='utf8').strip()
    if language != "":
      os.system("echo -n %s > /data/params/d/dp_locale" % language)
  elif os.path.isfile("/TICI"):
    pass
  else:
    pass
