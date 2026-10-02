// The language map page (school_languages/show): one big map of where a
// language's English learners go to school, beside cards for every language.
// Picking a card loads that language's JSON and swaps it into the map without
// leaving the page. Zoomed out, the map is a heatmap weighted by English
// learners; zoomed in, circles sized by English learners.
(function() {
  var ACCESS_TOKEN = 'pk.eyJ1IjoiZXRobmljbGEiLCJhIjoiY2psZTM1Z3dnMGh1aTNrb3lnb3YzZzMzeSJ9.5HGT4cTIUGjgFrfJGW0bXg';
  var STYLE = 'mapbox://styles/ethnicla/cjlhdx9ii05o82rp9w6r1008s';
  // The same area the small maps on the cards show (LanguageFootprint)
  var FRAME = [[-119.35, 33.35], [-116.0, 34.75]];
  var CIRCLE_COLOR = '#2f6fd6';
  var TOP_SCHOOLS = 15;
  var PLAY_DELAY = 900;

  function schoolYear(year) {
    return year + '-' + ('0' + ((year + 1) % 100)).slice(-2);
  }

  function format(number) {
    return number.toLocaleString('en-US');
  }

  function busiestSchool(points) {
    var max = 1;
    points.forEach(function(point) { max = Math.max.apply(null, [max].concat(point.counts)); });
    return max;
  }

  function setUp(panel) {
    var language = JSON.parse(panel.getAttribute('data-language'));
    var years = language.years;
    var index = years.indexOf(parseInt(panel.getAttribute('data-year'), 10));
    // Scale to the busiest school in any year, so years are comparable
    var maxCount = busiestSchool(language.points);
    var loaded = {};
    loaded[language.slug] = language;

    var slider = document.getElementById('school-language-year');
    var playButton = document.getElementById('school-language-play');
    var trend = document.getElementById('school-language-trend');
    var mapElement = panel.querySelector('.school-language-map');
    var map = null;
    var playTimer = null;

    function text(id, value) {
      document.getElementById(id).textContent = value;
    }

    function features() {
      return {
        type: 'FeatureCollection',
        features: language.points.filter(function(point) { return point.counts[index] > 0; }).map(function(point) {
          return {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [point.lng, point.lat] },
            properties: { name: point.name, district: point.district, count: point.counts[index] }
          };
        })
      };
    }

    function renderTable() {
      var body = document.getElementById('school-language-schools');
      body.innerHTML = '';
      language.points.filter(function(point) { return point.counts[index] > 0; })
        .sort(function(a, b) { return b.counts[index] - a.counts[index]; })
        .slice(0, TOP_SCHOOLS)
        .forEach(function(point) {
          var row = document.createElement('tr');
          [point.name, point.district, format(point.counts[index])].forEach(function(value, column) {
            var cell = document.createElement('td');
            cell.textContent = value;
            if (column === 2) { cell.className = 'text-end'; }
            row.appendChild(cell);
          });
          body.appendChild(row);
        });
    }

    function renderTrend() {
      var max = Math.max.apply(null, [1].concat(language.totals));
      Array.prototype.forEach.call(trend.querySelectorAll('.trend-bar'), function(bar, i) {
        var label = schoolYear(years[i]) + ': ' + format(language.totals[i]);
        bar.querySelector('.trend-fill').style.height = (100 * language.totals[i] / max).toFixed(1) + '%';
        bar.title = label;
        bar.setAttribute('aria-label', label + ' English learners');
        bar.classList.toggle('selected', i === index);
      });
    }

    function updateUrl() {
      window.history.replaceState(window.history.state, '', '/language-map/' + language.slug + '?year=' + years[index]);
    }

    function showYear(newIndex) {
      index = newIndex;
      var label = schoolYear(years[index]);
      slider.value = index;
      slider.setAttribute('aria-valuetext', label);
      text('school-language-year-label', label);
      text('school-language-total-year', label);
      text('school-language-total-count', format(language.totals[index]));
      renderTrend();
      renderTable();
      if (map && map.getSource('schools')) { map.getSource('schools').setData(features()); }
      updateUrl();
    }

    function markSelectedCard() {
      Array.prototype.forEach.call(document.querySelectorAll('.footprint-card'), function(card) {
        var selected = card.getAttribute('data-slug') === language.slug;
        card.classList.toggle('selected', selected);
        if (selected) { card.setAttribute('aria-current', 'true'); } else { card.removeAttribute('aria-current'); }
      });
    }

    function showLanguage(data) {
      language = data;
      maxCount = busiestSchool(language.points);
      var endonym = document.getElementById('language-title-endonym');
      endonym.textContent = language.endonym || '';
      endonym.hidden = !language.endonym;
      if (language.lang) { endonym.setAttribute('lang', language.lang); } else { endonym.removeAttribute('lang'); }
      ['language-title-name', 'school-language-total-name', 'school-language-table-name'].forEach(function(id) { text(id, language.name); });
      document.title = language.name + ' - Ethnic LA';
      markSelectedCard();
      if (map && map.getLayer('schools-heat')) {
        map.setPaintProperty('schools-heat', 'heatmap-weight', heatmapWeight());
        map.setPaintProperty('schools-circles', 'circle-radius', circleRadius());
      }
      showYear(index);
    }

    function loadLanguage(slug, push) {
      stopPlaying();
      var show = function(data) {
        loaded[slug] = data;
        // Add the history entry first; showLanguage then updates it in place
        if (push) { window.history.pushState({ languageMap: true }, '', '/language-map/' + data.slug + '?year=' + years[index]); }
        showLanguage(data);
      };
      if (loaded[slug]) { show(loaded[slug]); return; }
      panel.classList.add('loading');
      fetch('/language-map/' + encodeURIComponent(slug) + '.json', { headers: { Accept: 'application/json' } })
        .then(function(response) {
          if (!response.ok) { throw new Error(response.status); }
          return response.json();
        })
        .then(show)
        .catch(function() { window.location.href = '/language-map/' + slug; })
        .then(function() { panel.classList.remove('loading'); });
    }

    function stopPlaying() {
      clearInterval(playTimer);
      playTimer = null;
      playButton.textContent = 'Play';
    }

    // Square root, so schools with a few speakers still show next to ones with hundreds
    function heatmapWeight() {
      return ['sqrt', ['/', ['get', 'count'], maxCount]];
    }

    function circleRadius() {
      return ['interpolate', ['linear'], ['sqrt', ['/', ['get', 'count'], maxCount]], 0, 4, 1, 24];
    }

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

    Array.prototype.forEach.call(document.querySelectorAll('.footprint-card'), function(card) {
      card.addEventListener('click', function(event) {
        // Let modified clicks open the language in a new tab
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) { return; }
        event.preventDefault();
        loadLanguage(card.getAttribute('data-slug'), true);
        // Below the map on narrow screens, so bring the map into view
        if (panel.getBoundingClientRect().top < 0 || window.matchMedia('(max-width: 991px)').matches) {
          panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });
    });

    function onPopState(event) {
      if (!event.state || !event.state.languageMap) { return; }
      var match = window.location.pathname.match(/^\/language-map\/([^/]+)/);
      var year = parseInt(new URLSearchParams(window.location.search).get('year'), 10);
      if (years.indexOf(year) !== -1) { index = years.indexOf(year); }
      if (match) { loadLanguage(decodeURIComponent(match[1]), false); }
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
      map.addSource('schools', { type: 'geojson', data: features() });

      map.addLayer({
        id: 'schools-heat',
        type: 'heatmap',
        source: 'schools',
        maxzoom: 13,
        paint: {
          'heatmap-weight': heatmapWeight(),
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
          'circle-radius': circleRadius(),
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
        popup.appendChild(document.createTextNode(format(school.count) + ' ' + language.name + '-speaking English learners in ' + schoolYear(years[index])));
        new mapboxgl.Popup().setLngLat(event.features[0].geometry.coordinates).setDOMContent(popup).addTo(map);
      });
      map.on('mouseenter', 'schools-circles', function() { map.getCanvas().style.cursor = 'pointer'; });
      map.on('mouseleave', 'schools-circles', function() { map.getCanvas().style.cursor = ''; });
    });
  }

  document.addEventListener('turbolinks:load', function() {
    var panel = document.getElementById('language-panel');
    if (panel) { setUp(panel); }
  });
})();
