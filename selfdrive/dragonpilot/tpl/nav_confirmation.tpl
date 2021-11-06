<div><img src="https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/pin-s-l+000({{lon}},{{lat}})/{{lon}},{{lat}},14/300x300?access_token={{token}}" /></div>
<div style="padding: 5px; font-size: 10px;">{{addr}}</div>
<form name="navForm" method="post">
  <input type="hidden" name="addr" value="{{addr}}">
  <input type="hidden" name="lat" value="{{lat}}">
  <input type="hidden" name="lon" value="{{lon}}">
  <div style="padding: 5px;"><input type="submit" value="Start Navigation" ></div>
</form>