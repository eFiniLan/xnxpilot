import gettext
from common.params import Params
import os

locale_dir = "/data/openpilot/selfdrive/assets/locales"
supported_language = ["en-US", "zh-TW", "zh-CN", "ja-JP", "ko-KR"]

def events():
  if os.path.isfile("/EON"):
    locale = Params().get("dp_locale", encoding='utf8')
    locale = locale.strip() if locale is not None else "en-US"
  else:
    locale = "en-US"
  i18n = gettext.translation("events", localedir=locale_dir, fallback=True, languages=[locale])
  i18n.install()
  return i18n.gettext