document.addEventListener 'turbolinks:load', ->
  language_adder = ->
    select_id = '#ethnic_church_language_name'
    $(select_id).chosen({no_results_text: 'Language not found. <a id="add_new_language" href="#">Add</a>', placeholder_text_multiple: ' '})

    $('.chosen-search-input').change(->
      $('#add_new_language').click(->
        lang = $('.chosen-search-input').val()
        $(select_id).chosen('destroy')
        updated_languages = $(select_id).val().concat(lang)
        $(select_id).prepend("""<option value="#{lang}">#{lang}</option>""")
        $(select_id).val(updated_languages)
        $('.chosen-search-input').focus()
        language_adder()
        false
      )
    )
  language_adder()
