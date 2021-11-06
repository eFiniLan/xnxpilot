#!/usr/bin/env python3
'''
This script is used to clean up files prior publish to xnxpilot.
Run this in jetson device to clean up.

Do not run this unless you know what you are doing.
-- Rick Lan
'''

import os
import sys
import subprocess

PATH = "/data/openpilot"

VERSION = "0.8.9"

if not os.path.exists("/JETSON"):
  sys.exit("Please run this in Jetson device.")

# make sure we dont use prebuilt
os.system("echo -n 0 > /data/params/d/dp_prebuilt")
os.system("rm -fr %s/prebuilt" % PATH)

# model clean up
os.system("rm -fr %s/selfdrive/models/*.dlc" % PATH)

# ui clean up
subprocess.call(['sed -i -e "s#selfdrive/ui/_ui##g " ' + ('%s/.gitignore' % PATH)], shell=True)
subprocess.call(['sed -i -e "s#selfdrive/ui/_soundd##g " ' + ('%s/.gitignore' % PATH)], shell=True)
os.system("rm -fr %s/selfdrive/ui/*_aarch64" % PATH)
os.system("rm -fr %s/selfdrive/ui/*_larch64" % PATH)
os.system("rm -fr %s/selfdrive/ui/*_c3" % PATH)
os.system("rm -fr %s/selfdrive/ui/qt/*_aarch64" % PATH)
os.system("rm -fr %s/selfdrive/ui/qt/*_larch64" % PATH)
os.system("rm -fr %s/selfdrive/ui/qt/*_c3" % PATH)

os.system("rm -fr %s/selfdrive/ui/SConscript" % PATH)
os.system("rm -fr %s/selfdrive/ui/.gitignore" % PATH)
os.system("find %s/selfdrive/ui/ -name '*.a' -delete" % PATH)
os.system("find %s/selfdrive/ui/ -name '*.o' -delete" % PATH)
os.system("find %s/selfdrive/ui/ -name '*.h' -delete" % PATH)
os.system("find %s/selfdrive/ui/ -name '*.cc' -delete" % PATH)

# delete panda
os.system("rm -fr %s/panda/board/obj/panda.bin" % PATH)
os.system("rm -fr %s/panda/board/obj/panda.bin.signed" % PATH)

# misc
os.system("rm -fr %s/selfdrive/golden" % PATH)
os.system("rm -fr %s/installer/updater/updater.cc" % PATH)
os.system("rm -fr %s/phonelibs/curl/" % PATH)
os.system("rm -fr %s/phonelibs/boringssl/" % PATH)
os.system("rm -fr %s/phonelibs/mapbox-gl-native-qt/aarch64" % PATH)
os.system("rm -fr %s/phonelibs/snpe/aarch64*" % PATH)


# change version string
subprocess.call(["sed -i -e 's/.*/#define COMMA_VERSION \"" + ("%s-xnxpilot" % VERSION) + "\"/g' " + ('%s/selfdrive/common/version.h' % PATH)], shell=True)

