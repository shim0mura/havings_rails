# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(document).on "keydown", "#search-field", (e) ->
    if e.keyCode == 13
      console.log(e)
      tag = $("#search-field").val()
      console.log("https://" + location.host + "/search/tag?tag=" + tag)
      location.href = "https://" + location.host + "/search/tag?tag=" + tag
