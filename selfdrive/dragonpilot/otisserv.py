#!/usr/bin/env python3.8
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

from http.server import BaseHTTPRequestHandler, HTTPServer
from cgi import parse_header, parse_multipart
from urllib.parse import parse_qs, unquote
import json
import requests
from common.basedir import BASEDIR
from common.params import Params
params = Params()

hostName = ""
serverPort = 8082

class OtisServ(BaseHTTPRequestHandler):
  def do_GET(self):
    use_gmap = params.get_bool('dp_mapbox_gmap_enable')
    if self.path == '/logo.png':
      self.get_logo()
      return
    if self.path == '/?reset=1':
      params.put("NavDestination", "")
    if use_gmap:
      if self.path == '/style.css':
        self.send_response(200)
        self.send_header("Content-type", "text/css")
        self.end_headers()
        self.get_gmap_css()
        return
      elif self.path == '/index.js':
        self.send_response(200)
        self.send_header("Content-type", "text/javascript")
        self.end_headers()
        self.get_gmap_js()
        return
      else:
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        if self.get_gmap_key() is None:
          self.display_page_gmap_key()
          return
        if self.get_app_token() is None:
          self.display_page_app_token()
          return
        self.display_page_gmap()
    else:
      self.send_response(200)
      self.send_header("Content-type", "text/html")
      self.end_headers()
      if self.get_public_token() is None:
        self.display_page_public_token()
        return
      if self.get_app_token() is None:
        self.display_page_app_token()
        return
      self.display_page_addr_input()

  def do_POST(self):
    use_gmap = params.get_bool('dp_mapbox_gmap_enable')
    postvars = self.parse_POST()
    self.send_response(200)
    self.send_header("Content-type", "text/html")
    self.end_headers()

    if use_gmap:
      # gmap token
      if self.get_gmap_key() is None:
        if postvars is None or "gmap_key_val" not in postvars or postvars.get("gmap_key_val")[0] == "":
          self.display_page_gmap_key()
          return
        params.put('dp_mapbox_gmap_key', postvars.get("gmap_key_val")[0])

    else:
      # mapbox public key
      if self.get_public_token() is None:
        if postvars is None or "pk_token_val" not in postvars or postvars.get("pk_token_val")[0] == "":
          self.display_page_public_token()
          return
        token = postvars.get("pk_token_val")[0]
        if "pk." not in token:
          self.display_page_public_token("Your token was incorrect!")
          return
        params.put('dp_mapbox_token_pk', token)

    # app key
    if self.get_app_token() is None:
      if postvars is None or "sk_token_val" not in postvars or postvars.get("sk_token_val")[0] == "":
        self.display_page_app_token()
        return
      token = postvars.get("sk_token_val")[0]
      if "sk." not in token:
        self.display_page_app_token("Your token was incorrect!")
        return
      params.put('dp_mapbox_token_sk', token)

    # nav confirmed
    if postvars is not None:
      if "lat" in postvars and postvars.get("lat")[0] != "" and "lon" in postvars and postvars.get("lon")[0] != "":
        params.put('NavDestination', "{\"latitude\": %f, \"longitude\": %f}" % (float(postvars.get("lat")[0]), float(postvars.get("lon")[0])))

      # search
      if not use_gmap and "addr_val" in postvars:
        addr = postvars.get("addr_val")[0]
        if addr != "":
          real_addr, lat, lon = self.query_addr(addr)
          if real_addr is not None:
            self.display_page_nav_confirmation(real_addr, lon, lat)
            return
          else:
            self.display_page_addr_input("Place Not Found")
            return

    if not use_gmap:
      # display addr input
      self.display_page_addr_input()
    else:
      self.display_page_gmap()

  def get_logo(self):
    self.send_response(200)
    self.send_header('Content-type','image/png')
    self.end_headers()
    f = open("%s/selfdrive/assets/img_spinner_comma.png" % BASEDIR, "rb")
    self.wfile.write(f.read())
    f.close()

  def get_gmap_css(self):
    self.wfile.write(bytes(self.get_parsed_template("gmap_style.css"), "utf-8"))

  def get_gmap_js(self):
    lon, lat = self.get_last_lon_lat()
    self.wfile.write(bytes(self.get_parsed_template("gmap_index.js", {"{{lat}}": lat, "{{lon}}": lon}), "utf-8"))

  def display_page_gmap(self):
    self.wfile.write(bytes(self.get_parsed_template("gmap_index.html", {"{{gmap_key}}": self.get_gmap_key()}), "utf-8"))

  def get_gmap_key(self):
    token = params.get("dp_mapbox_gmap_key", encoding='utf8')
    if token is not None and token != "":
      return token.rstrip('\x00')
    return None

  def get_public_token(self):
    token = params.get("dp_mapbox_token_pk", encoding='utf8')
    if token is not None and token != "":
      return token.rstrip('\x00')
    return None

  def get_app_token(self):
    token = params.get("dp_mapbox_token_sk", encoding='utf8')
    if token is not None and token != "":
      return token.rstrip('\x00')
    return None

  def get_last_lon_lat(self):
    last_pos = Params().get("LastGPSPosition")
    if last_pos is not None and last_pos != "":
      l = json.loads(last_pos)
      return l["longitude"], l["latitude"]
    return "", ""

  def display_page_gmap_key(self):
    self.wfile.write(bytes(self.get_parsed_template("body", {"{{content}}": self.get_parsed_template("gmap_key_input")}), "utf-8"))

  def display_page_public_token(self, msg = ""):
    self.wfile.write(bytes(self.get_parsed_template("body", {"{{content}}": self.get_parsed_template("public_token_input", {"{{msg}}": msg})}), "utf-8"))

  def display_page_app_token(self, msg = ""):
    self.wfile.write(bytes(self.get_parsed_template("body", {"{{content}}": self.get_parsed_template("app_token_input", {"{{msg}}": msg})}), "utf-8"))

  def display_page_addr_input(self, msg = ""):
    self.wfile.write(bytes(self.get_parsed_template("body", {"{{content}}": self.get_parsed_template("addr_input", {"{{msg}}": msg})}), "utf-8"))

  def display_page_nav_confirmation(self, addr, lon, lat):
    content = self.get_parsed_template("addr_input", {"{{msg}}": ""}) + self.get_parsed_template("nav_confirmation", {"{{token}}": self.get_public_token(), "{{lon}}": lon, "{{lat}}": lat, "{{addr}}": addr})
    self.wfile.write(bytes(self.get_parsed_template("body", {"{{content}}": content }), "utf-8"))

  def get_parsed_template(self, name, replace = {}):
    f = open('%s/selfdrive/dragonpilot/tpl/%s.tpl' % (BASEDIR, name), mode='r', encoding='utf-8')
    content = f.read()
    for key in replace:
      content = content.replace(key, str(replace[key]))
    f.close()
    return content

  def query_addr(self, addr):
    if addr == "":
      return None, None, None
    query = "https://api.mapbox.com/geocoding/v5/mapbox.places/" + unquote(addr) + ".json?access_token=" + self.get_public_token() + "&limit=1"
    # focus on place around last gps position
    last_pos = Params().get("LastGPSPosition")
    if last_pos is not None and last_pos != "":
      l = json.loads(last_pos)
      query += "&proximity=%s,%s" % (l["longitude"], l["latitude"])

    r = requests.get(query)
    if r.status_code != 200:
      return None, None, None

    j = json.loads(r.text)
    if not j["features"]:
      return None, None, None

    feature = j["features"][0]
    return feature["place_name"], feature["center"][1], feature["center"][0]

  def parse_POST(self):
    ctype, pdict = parse_header(self.headers['content-type'])
    if ctype == 'application/x-www-form-urlencoded':
      length = int(self.headers['content-length'])
      postvars = parse_qs(
        self.rfile.read(length).decode('utf-8'),
        keep_blank_values=1)
    else:
      postvars = {}
    return postvars

def main():
  webServer = HTTPServer((hostName, serverPort), OtisServ)

  try:
    webServer.serve_forever()
  except KeyboardInterrupt:
    pass

  webServer.server_close()

if __name__ == "__main__":
  main()
