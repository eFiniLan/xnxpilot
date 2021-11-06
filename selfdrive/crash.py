"""Install exception handler for process crash."""
import os
import sys
import capnp
import traceback
import requests
from cereal import car
from datetime import datetime
from selfdrive.swaglog import cloudlog
from selfdrive.version import version
from selfdrive.version import version, branch, origin, branch, dirty, commit, get_git_commit
from common.params import Params

import sentry_sdk
from sentry_sdk import set_tag
from sentry_sdk.integrations.threading import ThreadingIntegration

CRASHES_DIR = '/data/community/crashes'

def save_exception(exc_text):
  if not os.path.exists(CRASHES_DIR):
    os.makedirs(CRASHES_DIR)

  log_file = '{}/{}'.format(CRASHES_DIR, datetime.now().strftime('%m-%d-%Y--%I:%M.%S-%p.log'))
  with open(log_file, 'w') as f:
    f.write(exc_text)
  print('Logged current crash to {}'.format(log_file))

ret = car.CarParams.new_message()
candidate = ret.carFingerprint

params = Params()
#uniqueID = op_params.get('uniqueID')
try:
  dongle_id = params.get("DongleId").decode('utf8')
except AttributeError:
  dongle_id = "None"
try:
  gitname = Params().get("GithubUsername", encoding='utf-8')
except:
  gitname = ""
try:
  ip = requests.get('https://checkip.amazonaws.com/').text.strip()
except Exception:
  ip = "255.255.255.255"
error_tags = {'dirty': dirty, 'dongle_id': dongle_id, 'branch': branch, 'remote': origin, 'fingerprintedAs': candidate, 'gitname':gitname}

dongle_id = Params().get("DongleId", encoding='utf-8')

def capture_exception(*args, **kwargs):
  save_exception(traceback.format_exc())
  exc_info = sys.exc_info()
  if not exc_info[0] is capnp.lib.capnp.KjException:
    save_exception(traceback.format_exc())
    sentry_sdk.capture_exception(*args, **kwargs)
    sentry_sdk.flush()  # https://github.com/getsentry/sentry-python/issues/291
  cloudlog.error("crash", exc_info=kwargs.get('exc_info', 1))

def bind_user(**kwargs) -> None:
    sentry_sdk.set_user(kwargs)

def capture_warning(warning_string):
  bind_user(id=dongle_id, ip_address=ip, name=gitname)
  sentry_sdk.capture_message(warning_string, level='warning')

def capture_info(info_string):
  bind_user(id=dongle_id, ip_address=ip, name=gitname)
  sentry_sdk.capture_message(info_string, level='info')

def bind_extra(**kwargs) -> None:
  for k, v in kwargs.items():
    sentry_sdk.set_tag(k, v)

def init() -> None:
  sentry_sdk.init("https://980a0cba712a4c3593c33c78a12446e1:fecab286bcaf4dba8b04f7cff0188e2d@sentry.io/1488600",
                  default_integrations=False, integrations=[ThreadingIntegration(propagate_hub=True)],
                  release=version)

sentry_sdk.set_user({"id": dongle_id})
sentry_sdk.set_user({"name": gitname})
sentry_sdk.set_tag("dirty", dirty)
sentry_sdk.set_tag("origin", origin)
sentry_sdk.set_tag("branch", branch)
sentry_sdk.set_tag("commit", commit)
