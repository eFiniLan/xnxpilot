#!/usr/bin/env python3
import os

if __name__ == "__main__":
  install_font = False

  if os.path.isfile("/EON"):
    if not os.path.isfile("/system/fonts/NotoSansCJKtc-Regular.otf"):
      os.system("mount -o remount,rw /system")
      os.system("rm -fr /system/fonts/NotoSansTC*.otf")
      os.system("rm -fr /system/fonts/NotoSansSC*.otf")
      os.system("rm -fr /system/fonts/NotoSansKR*.otf")
      os.system("rm -fr /system/fonts/NotoSansJP*.otf")
      os.system("cp -rf /data/openpilot/selfdrive/assets/fonts/NotoSansCJKtc-* /system/fonts/")
      os.system("cp -rf /data/openpilot/selfdrive/assets/fonts/fonts.xml /system/etc/fonts.xml")
      os.system("chmod 644 /system/etc/fonts.xml")
      os.system("chmod 644 /system/fonts/NotoSansCJKtc-*")
      os.system("mount -o remount,r /system")

  elif os.path.isfile("/TICI"):
    pass
  else:
    pass
