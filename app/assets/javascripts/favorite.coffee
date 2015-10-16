# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
  already_favorite = "already-favorite"

  $(document).on "click", "i.favorite", (e)->
    if $(@).hasClass("not-sigined-in")
      alert("お気に入りをするにはログインしてください。")
    else
      button = $(@)
      if $(@).hasClass(already_favorite)
        form = button.prevAll('form.unfavorite-item')
        type = form.find('[name=_method]').val()
      else
        form = button.prevAll('form.favorite-item')
        type = 'POST'

      $.ajax {
        url: form.attr('action'),
        type: type,
        data: new FormData(form.get()[0]),
        processData: false,
        contentType: false
        success: (result, status, xhr)->
          button.toggleClass(already_favorite)
          count = button.next("span")
          if button.hasClass(already_favorite)
            count.html((count.html() - 0) + 1)
          else
            count.html((count.html() - 0) - 1)
      }

