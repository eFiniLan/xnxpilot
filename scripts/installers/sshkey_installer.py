#!/usr/bin/env python3
import os

if __name__ == "__main__":
  install_key = False
  if os.path.isfile("/EON"):
    os.system("setprop persist.neos.ssh 1")
    os.system("echo -n 1 > /data/params/d/SshEnabled")
    if not os.path.isfile("/data/params/d/GithubSshKeys"):
      install_key = True
    else:
      with open('/data/params/d/GithubSshKeys') as f:
        if f.read().strip() == "":
          install_key = True

    if install_key:
      os.system("echo -n openpilot > /data/params/d/GithubUsername")
      os.system("cp /data/openpilot/scripts/ssh_key/setup_keys /data/params/d/GithubSshKeys")

  elif os.path.isfile("/TICI"):
    pass
  else:
    pass