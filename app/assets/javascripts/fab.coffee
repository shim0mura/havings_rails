$ ->
  showing_class = "is-showing-options"
  closing_class = "is-showing-options-x"
  $(document).on 'click', "#fab-button", (e)->
    # 何故かinner-fab-buttonsの範囲をクリックしても発火するので、
    # その場合はreturnする

    return if $(e.target).hasClass("inner-fab-buttons")
    if $(@).hasClass(showing_class)
      $(@).addClass(closing_class)
      $(@).removeClass(showing_class)
    else
      $(@).addClass(showing_class)
      $(@).removeClass(closing_class)
