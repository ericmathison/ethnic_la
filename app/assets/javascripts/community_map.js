// The language and ethnicity maps (school_languages/show, ethnicities/show):
// one big map of where a group is, beside cards for every group. Picking a
// card loads that group's JSON and swaps it into the map without leaving the
// page. Zoomed out, the map is a heatmap weighted by each place's count;
// zoomed in, circles sized by count. Groups with several years (languages)
// get a year slider and trend bars.
(function() {
  var ACCESS_TOKEN = 'pk.eyJ1IjoiZXRobmljbGEiLCJhIjoiY2psZTM1Z3dnMGh1aTNrb3lnb3YzZzMzeSJ9.5HGT4cTIUGjgFrfJGW0bXg';
  var STYLE = 'mapbox://styles/ethnicla/cjlhdx9ii05o82rp9w6r1008s';
  // The same area the small maps on the cards show (Footprint)
  var FRAME = [[-119.35, 33.35], [-116.0, 34.75]];
  var CIRCLE_COLOR = '#2f6fd6';
  var TOP_PLACES = 15;
  var PLAY_DELAY = 900;

  function schoolYear(year) {
    return year + '-' + ('0' + ((year + 1) % 100)).slice(-2);
  }

  function format(number) {
    return number.toLocaleString('en-US');
  }

  function busiestPlace(points) {
    var max = 1;
    points.forEach(function(point) { max = Math.max.apply(null, [max].concat(point.counts)); });
    return max;
  }

  function setUp(panel) {
    var group = JSON.parse(panel.getAttribute('data-group'));
    var basePath = panel.getAttribute('data-base-path');
    // Tracts hold more people than schools hold students, so the ethnicity map uses less
    var heatIntensity = parseFloat(panel.getAttribute('data-heat-intensity')) || 1.5;
    var years = group.years;
    var index = Math.max(0, years.indexOf(parseInt(panel.getAttribute('data-year'), 10)));
    // Scale to the busiest place in any year, so years are comparable
    var maxCount = busiestPlace(group.points);
    var loaded = {};
    loaded[group.slug] = group;

    // Only on maps with several years
    var slider = document.getElementById('map-year');
    var playButton = document.getElementById('map-play');
    var trend = document.getElementById('map-trend');
    var mapElement = panel.querySelector('.big-map');
    var map = null;
    var playTimer = null;

    function setText(id, value) {
      var element = document.getElementById(id);
      if (element) { element.textContent = value; }
    }

    function features() {
      return {
        type: 'FeatureCollection',
        features: group.points.filter(function(point) { return point.counts[index] > 0; }).map(function(point) {
          return {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [point.lng, point.lat] },
            properties: { name: point.name, district: point.district, count: point.counts[index] }
          };
        })
      };
    }

    function addRow(body, values) {
      var row = document.createElement('tr');
      values.forEach(function(value, column) {
        var cell = document.createElement('td');
        cell.textContent = value;
        if (column === values.length - 1) { cell.className = 'text-end'; }
        row.appendChild(cell);
      });
      body.appendChild(row);
    }

    // The group's own table rows if it has them, otherwise its busiest places
    function renderTable() {
      var body = document.getElementById('map-table-body');
      body.innerHTML = '';
      if (group.table) {
        group.table.forEach(function(row) { addRow(body, [row[0], format(row[1])]); });
        return;
      }
      group.points.filter(function(point) { return point.counts[index] > 0; })
        .sort(function(a, b) { return b.counts[index] - a.counts[index]; })
        .slice(0, TOP_PLACES)
        .forEach(function(point) { addRow(body, [point.name, point.district, format(point.counts[index])]); });
    }

    function renderTrend() {
      if (!trend) { return; }
      var max = Math.max.apply(null, [1].concat(group.totals));
      Array.prototype.forEach.call(trend.querySelectorAll('.trend-bar'), function(bar, i) {
        var label = schoolYear(years[i]) + ': ' + format(group.totals[i]);
        bar.querySelector('.trend-fill').style.height = (100 * group.totals[i] / max).toFixed(1) + '%';
        bar.title = label;
        bar.setAttribute('aria-label', label + ' ' + group.count_label);
        bar.classList.toggle('selected', i === index);
      });
    }

    function url() {
      return basePath + '/' + group.slug + (years.length > 1 ? '?year=' + years[index] : '');
    }

    function showYear(newIndex) {
      index = newIndex;
      if (slider) {
        var label = schoolYear(years[index]);
        slider.value = index;
        slider.setAttribute('aria-valuetext', label);
        setText('map-year-label', label);
        setText('map-total-year', label);
      }
      setText('map-total-count', format(group.totals[index]));
      renderTrend();
      renderTable();
      if (map && map.getSource('places')) { map.getSource('places').setData(features()); }
      window.history.replaceState(window.history.state, '', url());
    }

    function markSelectedCard() {
      Array.prototype.forEach.call(document.querySelectorAll('.footprint-card'), function(card) {
        var selected = card.getAttribute('data-slug') === group.slug;
        card.classList.toggle('selected', selected);
        if (selected) { card.setAttribute('aria-current', 'true'); } else { card.removeAttribute('aria-current'); }
      });
    }

    function showGroup(data) {
      group = data;
      maxCount = busiestPlace(group.points);
      var endonym = document.getElementById('map-title-endonym');
      if (endonym) {
        endonym.textContent = group.endonym || '';
        endonym.hidden = !group.endonym;
        if (group.lang) { endonym.setAttribute('lang', group.lang); } else { endonym.removeAttribute('lang'); }
      }
      Array.prototype.forEach.call(document.querySelectorAll('.map-group-name'), function(element) { element.textContent = group.name; });
      document.title = group.name + ' - Ethnic LA';
      markSelectedCard();
      if (map && map.getLayer('places-heat')) {
        map.setPaintProperty('places-heat', 'heatmap-weight', heatmapWeight());
        map.setPaintProperty('places-circles', 'circle-radius', circleRadius());
      }
      showYear(index);
    }

    function loadGroup(slug, push) {
      stopPlaying();
      var show = function(data) {
        loaded[slug] = data;
        // Add the history entry first; showGroup then updates it in place
        if (push) { window.history.pushState({ communityMap: true }, '', basePath + '/' + data.slug); }
        showGroup(data);
      };
      if (loaded[slug]) { show(loaded[slug]); return; }
      panel.classList.add('loading');
      fetch(basePath + '/' + encodeURIComponent(slug) + '.json', { headers: { Accept: 'application/json' } })
        .then(function(response) {
          if (!response.ok) { throw new Error(response.status); }
          return response.json();
        })
        .then(show)
        .catch(function() { window.location.href = basePath + '/' + slug; })
        .then(function() { panel.classList.remove('loading'); });
    }

    function stopPlaying() {
      if (!playButton) { return; }
      clearInterval(playTimer);
      playTimer = null;
      playButton.textContent = 'Play';
    }

    // Square root, so places with a few people still show next to ones with hundreds
    function heatmapWeight() {
      return ['sqrt', ['/', ['get', 'count'], maxCount]];
    }

    function circleRadius() {
      return ['interpolate', ['linear'], ['sqrt', ['/', ['get', 'count'], maxCount]], 0, 4, 1, 24];
    }

    if (slider) {
      slider.addEventListener('input', function() { stopPlaying(); showYear(parseInt(slider.value, 10)); });
      Array.prototype.forEach.call(trend.querySelectorAll('.trend-bar'), function(bar, i) {
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
    }

    Array.prototype.forEach.call(document.querySelectorAll('.footprint-card'), function(card) {
      card.addEventListener('click', function(event) {
        // Let modified clicks open the group in a new tab
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) { return; }
        event.preventDefault();
        loadGroup(card.getAttribute('data-slug'), true);
        // Below the map on narrow screens, so bring the map into view
        if (panel.getBoundingClientRect().top < 0 || window.matchMedia('(max-width: 991px)').matches) {
          panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });
    });

    function onPopState(event) {
      if (!event.state || !event.state.communityMap) { return; }
      var slug = window.location.pathname.slice(basePath.length + 1);
      var year = parseInt(new URLSearchParams(window.location.search).get('year'), 10);
      if (years.indexOf(year) !== -1) { index = years.indexOf(year); }
      if (slug) { loadGroup(decodeURIComponent(slug), false); }
    }
    window.addEventListener('popstate', onPopState);
    document.addEventListener('turbolinks:before-render', function() {
      stopPlaying();
      window.removeEventListener('popstate', onPopState);
    }, { once: true });

    markSelectedCard();
    renderTable();
    if (typeof mapboxgl === 'undefined') { return; }

    mapboxgl.accessToken = ACCESS_TOKEN;
    map = new mapboxgl.Map({ container: mapElement, style: STYLE, center: [-117.675, 34.05], zoom: 8 });
    map.fitBounds(FRAME, { animate: false });
    map.scrollZoom.disable();
    map.addControl(new mapboxgl.NavigationControl());

    map.on('load', function() {
      map.addSource('places', { type: 'geojson', data: features() });

      map.addLayer({
        id: 'places-heat',
        type: 'heatmap',
        source: 'places',
        maxzoom: 13,
        paint: {
          'heatmap-weight': heatmapWeight(),
          'heatmap-intensity': ['interpolate', ['linear'], ['zoom'], 8, heatIntensity, 12, heatIntensity * 2],
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
        id: 'places-circles',
        type: 'circle',
        source: 'places',
        minzoom: 10,
        paint: {
          'circle-radius': circleRadius(),
          'circle-color': CIRCLE_COLOR,
          'circle-stroke-color': '#ffffff',
          'circle-stroke-width': 1,
          'circle-opacity': circleOpacity,
          'circle-stroke-opacity': circleOpacity
        }
      });

      map.on('click', 'places-circles', function(event) {
        var place = event.features[0].properties;
        var popup = document.createElement('div');
        var name = document.createElement('strong');
        name.textContent = place.name;
        popup.appendChild(name);
        popup.appendChild(document.createElement('br'));
        popup.appendChild(document.createTextNode(place.district));
        popup.appendChild(document.createElement('br'));
        popup.appendChild(document.createTextNode(format(place.count) + ' ' + group.count_label +
          (years.length > 1 ? ' in ' + schoolYear(years[index]) : '')));
        new mapboxgl.Popup().setLngLat(event.features[0].geometry.coordinates).setDOMContent(popup).addTo(map);
      });
      map.on('mouseenter', 'places-circles', function() { map.getCanvas().style.cursor = 'pointer'; });
      map.on('mouseleave', 'places-circles', function() { map.getCanvas().style.cursor = ''; });
    });
  }

  document.addEventListener('turbolinks:load', function() {
    var panel = document.getElementById('map-panel');
    if (panel) { setUp(panel); }
  });
})();
