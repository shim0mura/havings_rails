$ ->
  showing_class = "is-showing-options"
  closing_class = "is-showing-options-x"
  $("#fab-button").click ->
    if $(@).hasClass(showing_class)
      $(@).addClass(closing_class)
      $(@).removeClass(showing_class)
    else
      $(@).addClass(showing_class)
      $(@).removeClass(closing_class)
