// Map of English learners by home language (school_languages/show). Zoomed out,
// schools show as a heatmap weighted by English learners; zoomed in, as circles
// sized by English learners. The year slider and trend bars switch years.
(function() {
  var ACCESS_TOKEN = 'pk.eyJ1IjoiZXRobmljbGEiLCJhIjoiY2psZTM1Z3dnMGh1aTNrb3lnb3YzZzMzeSJ9.5HGT4cTIUGjgFrfJGW0bXg';
  var STYLE = 'mapbox://styles/ethnicla/cjlhdx9ii05o82rp9w6r1008s';
  var CIRCLE_COLOR = '#2f6fd6';
  var TOP_SCHOOLS = 15;
  var PLAY_DELAY = 900;

  function schoolYear(year) {
    return year + '-' + ('0' + ((year + 1) % 100)).slice(-2);
  }

  function format(number) {
    return number.toLocaleString('en-US');
  }

  function features(points, index) {
    return points.filter(function(point) { return point.counts[index] > 0; }).map(function(point) {
      return {
        type: 'Feature',
        geometry: { type: 'Point', coordinates: [point.lng, point.lat] },
        properties: { name: point.name, district: point.district, count: point.counts[index] }
      };
    });
  }

  function buildMap(element) {
    var points = JSON.parse(element.getAttribute('data-points'));
    var years = JSON.parse(element.getAttribute('data-years'));
    var language = element.getAttribute('data-language');
    var index = years.indexOf(parseInt(element.getAttribute('data-year'), 10));

    // Scale to the busiest school in any year, so maps of different years are comparable
    var maxCount = 1;
    points.forEach(function(point) { maxCount = Math.max.apply(null, [maxCount].concat(point.counts)); });

    var slider = document.getElementById('school-language-year');
    var playButton = document.getElementById('school-language-play');
    var bars = document.querySelectorAll('.school-language-trend .trend-bar');
    var map = null;
    var playTimer = null;

    function totalFor(i) {
      return points.reduce(function(sum, point) { return sum + point.counts[i]; }, 0);
    }

    function renderTable() {
      var rows = points.filter(function(point) { return point.counts[index] > 0; })
        .sort(function(a, b) { return b.counts[index] - a.counts[index]; })
        .slice(0, TOP_SCHOOLS);
      var body = document.getElementById('school-language-schools');
      body.innerHTML = '';
      rows.forEach(function(point) {
        var row = document.createElement('tr');
        [point.name, point.district, format(point.counts[index])].forEach(function(text, column) {
          var cell = document.createElement('td');
          cell.textContent = text;
          if (column === 2) { cell.className = 'text-end'; }
          row.appendChild(cell);
        });
        body.appendChild(row);
      });
    }

    function showYear(newIndex) {
      index = newIndex;
      var label = schoolYear(years[index]);
      slider.value = index;
      document.getElementById('school-language-year-label').textContent = label;
      document.getElementById('school-language-total-year').textContent = label;
      document.getElementById('school-language-table-year').textContent = label;
      document.getElementById('school-language-year-field').value = years[index];
      Array.prototype.forEach.call(bars, function(bar, i) { bar.classList.toggle('selected', i === index); });
      renderTable();
      if (map && map.getSource('schools')) {
        map.getSource('schools').setData({ type: 'FeatureCollection', features: features(points, index) });
      }
      var url = new URL(window.location.href);
      url.searchParams.set('year', years[index]);
      window.history.replaceState(window.history.state, '', url);
    }

    function stopPlaying() {
      clearInterval(playTimer);
      playTimer = null;
      playButton.textContent = 'Play';
    }

    slider.addEventListener('input', function() { stopPlaying(); showYear(parseInt(slider.value, 10)); });
    Array.prototype.forEach.call(bars, function(bar, i) {
      bar.addEventListener('click', function() { stopPlaying(); showYear(i); });
    });
    playButton.addEventListener('click', function() {
      if (playTimer) { stopPlaying(); return; }
      playButton.textContent = 'Pause';
      if (index === years.length - 1) { showYear(0); }
      playTimer = setInterval(function() {
        if (index >= years.length - 1) { stopPlaying(); return; }
        showYear(index + 1);
      }, PLAY_DELAY);
    });
    document.addEventListener('turbolinks:before-render', stopPlaying, { once: true });

    // Type-to-search picker. Chosen triggers jQuery change events, not native ones.
    var select = $('#school-language-select');
    select.chosen({ search_contains: true, width: '100%', no_results_text: 'No language matches' });
    select.on('change', function() { select.closest('form').submit(); });
    document.addEventListener('turbolinks:before-cache', function() { select.chosen('destroy'); }, { once: true });

    renderTable();
    if (typeof mapboxgl === 'undefined') { return; }

    mapboxgl.accessToken = ACCESS_TOKEN;
    map = new mapboxgl.Map({ container: element, style: STYLE, center: [-117.9, 34.0], zoom: 8 });
    map.scrollZoom.disable();
    map.addControl(new mapboxgl.NavigationControl());

    map.on('load', function() {
      map.addSource('schools', { type: 'geojson', data: { type: 'FeatureCollection', features: features(points, index) } });

      map.addLayer({
        id: 'schools-heat',
        type: 'heatmap',
        source: 'schools',
        maxzoom: 13,
        paint: {
          // Square root, so schools with a few speakers still show next to ones with hundreds
          'heatmap-weight': ['sqrt', ['/', ['get', 'count'], maxCount]],
          'heatmap-intensity': ['interpolate', ['linear'], ['zoom'], 8, 1.5, 12, 3],
          'heatmap-radius': ['interpolate', ['linear'], ['zoom'], 8, 14, 12, 30],
          'heatmap-opacity': ['interpolate', ['linear'], ['zoom'], 11, 0.85, 13, 0],
          'heatmap-color': [
            'interpolate', ['linear'], ['heatmap-density'],
            0, 'rgba(47, 111, 214, 0)', 0.15, 'rgba(120, 165, 235, 0.6)', 0.4, '#5b8fe0', 0.7, '#2f6fd6', 1, '#0d2c66'
          ]
        }
      });

      var circleOpacity = ['interpolate', ['linear'], ['zoom'], 10, 0, 12, 0.8];
      map.addLayer({
        id: 'schools-circles',
        type: 'circle',
        source: 'schools',
        minzoom: 10,
        paint: {
          'circle-radius': ['interpolate', ['linear'], ['sqrt', ['/', ['get', 'count'], maxCount]], 0, 4, 1, 24],
          'circle-color': CIRCLE_COLOR,
          'circle-stroke-color': '#ffffff',
          'circle-stroke-width': 1,
          'circle-opacity': circleOpacity,
          'circle-stroke-opacity': circleOpacity
        }
      });

      map.on('click', 'schools-circles', function(event) {
        var school = event.features[0].properties;
        var popup = document.createElement('div');
        var name = document.createElement('strong');
        name.textContent = school.name;
        popup.appendChild(name);
        popup.appendChild(document.createElement('br'));
        popup.appendChild(document.createTextNode(school.district));
        popup.appendChild(document.createElement('br'));
        popup.appendChild(document.createTextNode(format(school.count) + ' ' + language + '-speaking English learners in ' + schoolYear(years[index])));
        new mapboxgl.Popup().setLngLat(event.features[0].geometry.coordinates).setDOMContent(popup).addTo(map);
      });
      map.on('mouseenter', 'schools-circles', function() { map.getCanvas().style.cursor = 'pointer'; });
      map.on('mouseleave', 'schools-circles', function() { map.getCanvas().style.cursor = ''; });
    });
  }

  document.addEventListener('turbolinks:load', function() {
    Array.prototype.forEach.call(document.querySelectorAll('.school-language-map'), buildMap);
  });
})();
