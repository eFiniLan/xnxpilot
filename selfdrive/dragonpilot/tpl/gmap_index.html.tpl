<!DOCTYPE html>
<html>
  <head>
    <title>dragonpilot</title>
    <script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
    <link rel="stylesheet" type="text/css" href="./style.css" />
    <script src="./index.js"></script>
    <meta name="viewport" content="width=device-width">
  </head>
  <body>
    <div style="place-items: center; padding: 5px; font-weight: bold;" align="center"><a href="?reset=1"><img style="width: 100px; height: 100px; background-color: black;" src="logo.png"></a></div>
    <input
      id="pac-input"
      class="controls"
      type="text"
      placeholder="Search Box"
    />
    <div id="map"></div>

    <!-- Async script executes immediately and must be after any DOM elements used in callback. -->
    <script
      src="https://maps.googleapis.com/maps/api/js?key={{gmap_key}}&callback=initAutocomplete&libraries=places&v=weekly"
      async
    ></script>
  </body>
</html>