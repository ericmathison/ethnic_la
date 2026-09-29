// Heatmaps for pages that render shared/_heatmap. Zoomed out, locations show as
// a heatmap; zoomed in (or when there are only a few), as individual pins.
(function() {
  var ACCESS_TOKEN = 'pk.eyJ1IjoiZXRobmljbGEiLCJhIjoiY2psZTM1Z3dnMGh1aTNrb3lnb3YzZzMzeSJ9.5HGT4cTIUGjgFrfJGW0bXg';
  var STYLE = 'mapbox://styles/ethnicla/cjlhdx9ii05o82rp9w6r1008s';
  var FEW_POINTS = 15;
  var PIN_COLOR = '#2f6fd6';

  function buildHeatmap(element) {
    if (typeof mapboxgl === 'undefined') { return; }

    var points = JSON.parse(element.getAttribute('data-points'));
    var showStatus = element.getAttribute('data-show-status') === 'true';
    var fewPoints = points.length < FEW_POINTS;

    mapboxgl.accessToken = ACCESS_TOKEN;
    var map = new mapboxgl.Map({ container: element, style: STYLE, center: [-118, 33.91], zoom: 8.5 });
    map.scrollZoom.disable();
    map.addControl(new mapboxgl.NavigationControl());

    map.on('load', function() {
      map.addSource('locations', {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: points.map(function(point) {
            return {
              type: 'Feature',
              geometry: { type: 'Point', coordinates: [point.lng, point.lat] },
              properties: { name: point.name, status: point.status || 'verified' }
            };
          })
        }
      });

      map.addLayer({
        id: 'locations-heat',
        type: 'heatmap',
        source: 'locations',
        maxzoom: 13,
        paint: {
          'heatmap-weight': 0.54,
          'heatmap-radius': 17,
          'heatmap-opacity': fewPoints ? 0.5 : ['interpolate', ['linear'], ['zoom'], 11, 1, 13, 0],
          'heatmap-color': [
            'interpolate', ['linear'], ['heatmap-density'],
            0, 'rgba(0, 0, 255, 0)', 0.1, 'hsl(225, 73%, 57%)', 0.3, 'cyan', 0.5, 'lime', 0.7, 'yellow', 1, 'red'
          ]
        }
      });

      var pinOpacity = fewPoints ? 1 : ['interpolate', ['linear'], ['zoom'], 10, 0, 12, 1];
      map.addLayer({
        id: 'locations-pins',
        type: 'circle',
        source: 'locations',
        paint: {
          'circle-radius': 6,
          // Admins see unverified centers in orange and not-found centers in gray.
          'circle-color': showStatus ? ['match', ['get', 'status'], 'unverified', '#e8a33d', 'not_found', '#8b8b8b', PIN_COLOR] : PIN_COLOR,
          'circle-stroke-color': '#ffffff',
          'circle-stroke-width': 1,
          'circle-opacity': pinOpacity,
          'circle-stroke-opacity': pinOpacity
        }
      });

      map.on('click', 'locations-pins', function(event) {
        var feature = event.features[0];
        new mapboxgl.Popup().setLngLat(feature.geometry.coordinates).setText(feature.properties.name).addTo(map);
      });
      map.on('mouseenter', 'locations-pins', function() { map.getCanvas().style.cursor = 'pointer'; });
      map.on('mouseleave', 'locations-pins', function() { map.getCanvas().style.cursor = ''; });
    });
  }

  document.addEventListener('turbolinks:load', function() {
    Array.prototype.forEach.call(document.querySelectorAll('.heatmap'), buildHeatmap);
  });
})();
