// Search, sorting, and category filters for the cards on the language and
// ethnicity maps (shared/_footprint_wall).
(function() {
  function setUp(wall) {
    var search = document.getElementById('footprint-search');
    var empty = document.getElementById('footprint-search-empty');
    var clear = document.getElementById('footprint-search-clear');
    var key = wall.querySelector('.footprint-key');
    var cards = Array.prototype.slice.call(wall.querySelectorAll('.footprint-card'));
    var category = '';

    function filter() {
      var query = search.value.trim().toLowerCase();
      var matches = 0;
      key.hidden = query !== '' || category !== '';
      cards.forEach(function(card) {
        var match = (!query || card.dataset.name.indexOf(query) !== -1 || card.dataset.endonym.indexOf(query) !== -1) &&
          (!category || card.dataset.category === category);
        card.hidden = !match;
        if (match) { matches++; }
      });
      empty.hidden = matches > 0;
      clear.hidden = search.value === '';
    }

    function press(buttons, pressed) {
      Array.prototype.forEach.call(buttons, function(button) {
        button.classList.toggle('active', button === pressed);
        button.setAttribute('aria-pressed', button === pressed ? 'true' : 'false');
      });
    }

    function clearSearch() {
      search.value = '';
      filter();
      search.focus();
    }

    search.addEventListener('input', filter);
    search.addEventListener('keydown', function(event) {
      if (event.key === 'Escape' && search.value) { clearSearch(); }
    });
    clear.addEventListener('click', clearSearch);

    var categoryButtons = wall.querySelectorAll('[data-category]:not(.footprint-card)');
    Array.prototype.forEach.call(categoryButtons, function(button) {
      button.addEventListener('click', function() {
        category = button.dataset.category;
        press(categoryButtons, button);
        filter();
      });
    });

    var sortButtons = wall.querySelectorAll('[data-sort]');
    Array.prototype.forEach.call(sortButtons, function(button) {
      button.addEventListener('click', function() {
        var bySize = button.dataset.sort === 'size';
        press(sortButtons, button);
        var grid = wall.querySelector('.footprint-grid');
        // Only cards are sorted; the key that explains them stays first
        cards.slice().sort(function(a, b) {
          if (bySize) { return b.dataset.size - a.dataset.size; }
          return a.dataset.name.localeCompare(b.dataset.name);
        }).forEach(function(card) { grid.appendChild(card); });
      });
    });
  }

  document.addEventListener('turbolinks:load', function() {
    var wall = document.querySelector('.footprint-wall');
    if (wall) { setUp(wall); }
  });
})();
