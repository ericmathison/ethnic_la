$(->
  language_adder = ->
    $('#language_name').chosen({no_results_text: 'Language not found. <a id="add_new_language" href="#">Add</a>', placeholder_text_multiple: ' '})

    $('.chosen-search-input').change(->
      $('#add_new_language').click(->
        lang = $('.chosen-search-input').val()
        $('#language_name').chosen('destroy')
        updated_languages = $('#language_name').val().concat(lang)
        $('#language_name').prepend("""<option value="#{lang}">#{lang}</option>""")
        $('#language_name').val(updated_languages)
        $('.chosen-search-input').focus()
        language_adder()
        false
      )
    )
  language_adder()
)
