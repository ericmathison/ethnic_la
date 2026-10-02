// Search and sort for the language cards on the language map page (school_languages/show).
(function() {
  function setUp(page) {
    var search = document.getElementById('language-search');
    var empty = document.getElementById('language-search-empty');
    var key = page.querySelector('.footprint-key');
    var cards = Array.prototype.slice.call(page.querySelectorAll('.footprint-card'));

    search.addEventListener('input', function() {
      var query = search.value.trim().toLowerCase();
      var matches = 0;
      key.hidden = query !== '';
      cards.forEach(function(card) {
        var match = !query || card.dataset.name.indexOf(query) !== -1 || card.dataset.endonym.indexOf(query) !== -1;
        card.hidden = !match;
        if (match) { matches++; }
      });
      empty.hidden = matches > 0;
    });

    Array.prototype.forEach.call(page.querySelectorAll('[data-sort]'), function(button) {
      button.addEventListener('click', function() {
        var bySize = button.dataset.sort === 'size';
        Array.prototype.forEach.call(page.querySelectorAll('[data-sort]'), function(other) {
          other.classList.toggle('active', other === button);
          other.setAttribute('aria-pressed', other === button ? 'true' : 'false');
        });
        Array.prototype.forEach.call(page.querySelectorAll('.footprint-grid'), function(grid) {
          // Only cards are sorted; the key that explains them stays first
          Array.prototype.slice.call(grid.querySelectorAll('.footprint-card')).sort(function(a, b) {
            if (bySize) { return b.dataset.size - a.dataset.size; }
            return a.dataset.name.localeCompare(b.dataset.name);
          }).forEach(function(card) { grid.appendChild(card); });
        });
      });
    });
  }

  document.addEventListener('turbolinks:load', function() {
    var page = document.querySelector('.language-wall');
    if (page) { setUp(page); }
  });
})();
