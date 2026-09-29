document.addEventListener('turbolinks:load', function() {
  var languageAdder = function() {
    var selectId = '#ethnic_church_language_name';
    $(selectId).chosen({no_results_text: 'Language not found. <a id="add_new_language" href="#">Add</a>', placeholder_text_multiple: ' '});

    $('.chosen-search-input').change(function() {
      $('#add_new_language').click(function() {
        var lang = $('.chosen-search-input').val();
        $(selectId).chosen('destroy');
        var updatedLanguages = $(selectId).val().concat(lang);
        $(selectId).prepend($('<option>').val(lang).text(lang));
        $(selectId).val(updatedLanguages);
        $('.chosen-search-input').focus();
        languageAdder();
        return false;
      });
    });
  };
  languageAdder();
});
