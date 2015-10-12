# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->

  showing_notification_class = "show-notification"
  notification_button = "#notification_button"
  notification_overlay = "#notification_overlay"
  notification_wrapper = "#notification"
  already_read = "already-read"

  close_notification = (target)->
    target.removeClass(showing_notification_class)
    $(notification_overlay).hide()
    $(notification_wrapper).hide()

  $(document).on 'click', notification_button, (e)->
    if $(@).hasClass(showing_notification_class)
      close_notification($(@))
    else
      $(@).addClass(showing_notification_class)
      $(notification_overlay).show()
      $(notification_wrapper).show()

      unless $(@).hasClass(already_read)
        button = $(@)
        form = $(@).nextAll('form')
        $.ajax {
          url: form.attr('action'),
          type: 'PUT',
          data: new FormData(form.get()[0]),
          processData: false,
          contentType: false
          success: (result, status, xhr)->
            button.addClass(already_read)
        }

  $(document).on 'click', notification_overlay, (e)->
    close_notification($(notification_button))
