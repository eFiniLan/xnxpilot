#!/usr/bin/env python3
# The MIT License
#
# Copyright (c) 2019-, Rick Lan, dragonpilot community, and a number of other of contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

'''
This is a service that broadcast dp config values to openpilot's messaging queues
'''
import cereal.messaging as messaging

from common.dp_conf import confs, get_struct_name, to_struct_val
from common.params import Params, put_nonblocking
import os
from selfdrive.hardware import HARDWARE
params = Params()
from common.dp_common import param_get, get_last_modified
from common.dp_time import LAST_MODIFIED_SYSTEMD
from selfdrive.dragonpilot.dashcamd import Dashcamd
from selfdrive.dragonpilot.appd import Appd
from selfdrive.hardware import EON
import socket
from common.realtime import Ratekeeper
import threading
from selfdrive.dragonpilot.gpx_uploader import gpx_uploader_thread

PARAM_PATH = params.get_params_path() + '/d/'

HERTZ = 1

last_modified_confs = {}

def confd_thread():
  sm = messaging.SubMaster(['deviceState'])
  pm = messaging.PubMaster(['dragonConf'])

  last_dp_msg = None
  frame = 0
  update_params = False
  modified = None
  last_modified = None
  last_modified_check = None
  started = False
  free_space = 1
  battery_percent = 0
  overheat = False
  last_started = False
  dashcamd = Dashcamd()
  appd = Appd()
  is_eon = EON
  rk = Ratekeeper(HERTZ, print_delay_threshold=None)  # Keeps rate at 2 hz
  uploader_thread = None

  while True:
    if uploader_thread is None:
      uploader_thread = threading.Thread(target=gpx_uploader_thread)
      uploader_thread.start()

    msg = messaging.new_message('dragonConf')
    if last_dp_msg is not None:
      msg.dragonConf = last_dp_msg

    '''
    ===================================================
    load thermald data every 3 seconds
    ===================================================
    '''
    if frame % (HERTZ * 3) == 0:
      started, free_space, battery_percent, overheat = pull_thermald(frame, sm, started, free_space, battery_percent, overheat)
    setattr(msg.dragonConf, get_struct_name('dp_thermal_started'), started)
    setattr(msg.dragonConf, get_struct_name('dp_thermal_overheat'), overheat)
    '''
    ===================================================
    hotspot on boot
    we do it after 30 secs just in case
    ===================================================
    '''
    if is_eon and frame == (HERTZ * 30) and param_get("dp_hotspot_on_boot", "bool", False):
      os.system("service call wifi 37 i32 0 i32 1 &")
    '''
    ===================================================
    check dp_last_modified every second
    ===================================================
    '''
    if not update_params:
      last_modified_check, modified = get_last_modified(LAST_MODIFIED_SYSTEMD, last_modified_check, modified)
      if last_modified != modified:
        update_params = True
        last_modified = modified
    '''
    ===================================================
    conditionally set update_params to true 
    ===================================================
    '''
    # force updating param when `started` changed
    if last_started != started:
      update_params = True

    if frame == 0:
      update_params = True
    '''
    ===================================================
    push param vals to message
    ===================================================
    '''
    if update_params:
      msg = update_conf_all(confs, msg, frame == 0)
      update_params = False
    '''
    ===================================================
    push once
    ===================================================
    '''
    if frame == 0:
      setattr(msg.dragonConf, get_struct_name('dp_locale'), params.get("dp_locale"))
      # mirror EndToEndToggle to dp_lane_less_model_ctrl first time, after all
      put_nonblocking('dp_lane_less_mode_ctrl', params.get('EndToEndToggle'))
    '''
    ===================================================
    push ip addr every 10 secs
    ===================================================
    '''
    if frame % (HERTZ * 10) == 0:
      msg = update_ip(msg)
    '''
    ===================================================
    update msg based on some custom logic
    ===================================================
    '''
    msg = update_custom_logic(msg)
    '''
    ===================================================
    battery ctrl every 30 secs
    PowerMonitor in thermald turns back on every mins
    so lets turn it off more frequent
    ===================================================
    '''
    # if frame % (HERTZ * 30) == 0:
    #   last_charging_ctrl = process_charging_ctrl(msg, last_charging_ctrl, battery_percent)
    '''
    ===================================================
    dashcam
    ===================================================
    '''
    if msg.dragonConf.dpDashcamd and frame % HERTZ == 0:
      dashcamd.run(started, free_space)
    '''
    ===================================================
    appd
    ===================================================
    '''
    if msg.dragonConf.dpAppd:
      appd.update(started)
    '''
    ===================================================
    finalise
    ===================================================
    '''
    last_dp_msg = msg.dragonConf
    last_started = started
    pm.send('dragonConf', msg)
    frame += 1
    rk.keep_time()

def update_conf(msg, conf, first_run = False):
  conf_type = conf.get('conf_type')

  # skip checking since modified date time hasn't been changed.
  if (last_modified_confs.get(conf['name'])) is not None and last_modified_confs.get(conf['name']) == os.stat(PARAM_PATH + conf['name']).st_mtime:
    return msg

  if 'param' in conf_type and 'struct' in conf_type:
    update_this_conf = True

    if not first_run:
      update_once = conf.get('update_once')
      if update_once is not None and update_once is True:
        return msg
      if update_this_conf:
        update_this_conf = check_dependencies(msg, conf)

    if update_this_conf:
      msg = set_message(msg, conf)
      if os.path.isfile(PARAM_PATH + conf['name']):
        last_modified_confs[conf['name']] = os.stat(PARAM_PATH + conf['name']).st_mtime
  return msg

def update_conf_all(confs, msg, first_run = False):
  for conf in confs:
    msg = update_conf(msg, conf, first_run)
  return msg

def process_charging_ctrl(msg, last_charging_ctrl, battery_percent):
  charging_ctrl = msg.dragonConf.dpChargingCtrl
  if last_charging_ctrl != charging_ctrl:
    HARDWARE.set_battery_charging(True)
  if charging_ctrl:
    if battery_percent >= msg.dragonConf.dpDischargingAt and HARDWARE.get_battery_charging():
      HARDWARE.set_battery_charging(False)
    elif battery_percent <= msg.dragonConf.dpChargingAt and not HARDWARE.get_battery_charging():
      HARDWARE.set_battery_charging(True)
  return charging_ctrl


def pull_thermald(frame, sm, started, free_space, battery_percent, overheat):
  sm.update(0)
  if sm.updated['deviceState']:
    started = sm['deviceState'].started
    free_space = sm['deviceState'].freeSpacePercent
    battery_percent = sm['deviceState'].batteryPercent
    overheat = sm['deviceState'].thermalStatus >= 2
  return started, free_space, battery_percent, overheat

def update_custom_logic(msg):
  if msg.dragonConf.dpAtl:
    msg.dragonConf.dpAllowGas = True
    msg.dragonConf.dpGearCheck = False
    if not msg.dragonConf.dpAtlOpLong:
      msg.dragonConf.dpFollowingProfileCtrl = False
      msg.dragonConf.dpAccelProfileCtrl = False
  if msg.dragonConf.dpLcMinMph > msg.dragonConf.dpLcAutoMinMph:
    put_nonblocking('dp_lc_auto_min_mph', str(msg.dragonConf.dpLcMinMph))
    msg.dragonConf.dpLcAutoMinMph = msg.dragonConf.dpLcMinMph
  # if msg.dragonConf.dpSrCustom <= 4.99 and msg.dragonConf.dpSrStock > 0:
  #   put_nonblocking('dp_sr_custom', str(msg.dragonConf.dpSrStock))
  #   msg.dragonConf.dpSrCustom = msg.dragonConf.dpSrStock
  # if msg.dragonConf.dpAppWaze or msg.dragonConf.dpAppHr:
  #   msg.dragonConf.dpDrivingUi = False
  # if not msg.dragonConf.dpDriverMonitor:
  #   msg.dragonConf.dpUiFace = False
  return msg


def update_ip(msg):
  val = 'N/A'
  s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  try:
    # doesn't even have to be reachable
    s.connect(('10.255.255.255', 1))
    IP = s.getsockname()[0]
  except:
    IP = 'N/A'
  finally:
    s.close()
  setattr(msg.dragonConf, get_struct_name('dp_ip_addr'), IP)
  return msg


def set_message(msg, conf):
  val = params.get(conf['name'], encoding='utf8')
  if val is not None:
    val = val.rstrip('\x00')
  else:
    val = conf.get('default')
    params.put(conf['name'], str(val))
  struct_val = to_struct_val(conf['name'], val)
  orig_val = struct_val
  if struct_val is not None:
    if conf.get('min') is not None:
      struct_val = max(struct_val, conf.get('min'))
    if conf.get('max') is not None:
      struct_val = min(struct_val, conf.get('max'))
  if orig_val != struct_val:
    params.put(conf['name'], str(struct_val))
  setattr(msg.dragonConf, get_struct_name(conf['name']), struct_val)
  return msg

def check_dependencies(msg, conf):
  passed = True
  # if has dependency and the depend param val is not in depend_vals, we dont update that conf val
  # this should reduce chance of reading unnecessary params
  dependencies = conf.get('depends')
  if dependencies is not None:
    for dependency in dependencies:
      if getattr(msg.dragonConf, get_struct_name(dependency['name'])) not in dependency['vals']:
        passed = False
        break
  return passed

def main():
  confd_thread()

if __name__ == "__main__":
  main()
