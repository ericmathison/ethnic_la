// Search and sort for the language map's browse page (school_languages/browse).
(function() {
  function setUp(page) {
    var search = document.getElementById('language-search');
    var empty = document.getElementById('language-search-empty');
    var smaller = document.getElementById('smaller-languages');
    var cards = Array.prototype.slice.call(page.querySelectorAll('.footprint-card'));

    search.addEventListener('input', function() {
      var query = search.value.trim().toLowerCase();
      var matchesInSmaller = 0;
      var matches = 0;
      cards.forEach(function(card) {
        var match = !query || card.dataset.name.indexOf(query) !== -1 || card.dataset.endonym.indexOf(query) !== -1;
        card.hidden = !match;
        if (match) {
          matches++;
          if (smaller && smaller.contains(card)) { matchesInSmaller++; }
        }
      });
      // Open the smaller languages when the only matches are in there
      if (smaller && query && matchesInSmaller > 0 && matchesInSmaller === matches) { smaller.open = true; }
      empty.hidden = matches > 0;
    });

    Array.prototype.forEach.call(page.querySelectorAll('[data-sort]'), function(button, _, buttons) {
      button.addEventListener('click', function() {
        var bySize = button.dataset.sort === 'size';
        Array.prototype.forEach.call(page.querySelectorAll('[data-sort]'), function(other) {
          other.classList.toggle('active', other === button);
          other.setAttribute('aria-pressed', other === button ? 'true' : 'false');
        });
        Array.prototype.forEach.call(page.querySelectorAll('.footprint-grid'), function(grid) {
          Array.prototype.slice.call(grid.children).sort(function(a, b) {
            if (bySize) { return b.dataset.size - a.dataset.size; }
            return a.dataset.name.localeCompare(b.dataset.name);
          }).forEach(function(card) { grid.appendChild(card); });
        });
      });
    });
  }

  document.addEventListener('turbolinks:load', function() {
    var page = document.querySelector('.language-browse');
    if (page) { setUp(page); }
  });
})();
