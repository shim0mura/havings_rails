# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
  $(document).on("change", "#change-password", (e)->
    $(@).closest("#change_password_or_not").next(".change-password").toggle("fast")
  )
