// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery-ui/datepicker-ja
//= require tag-it
//= require material
//= require twitter/typeahead.min
//= require_tree .
function createToast(message) {
  'use strict';
  var snackbar = document.createElement('div'),
      text = document.createElement('div');
  snackbar.classList.add('mdl-snackbar');
  text.classList.add('mdl-snackbar__text');
  text.innerText = message;
  snackbar.appendChild(text);
  document.body.appendChild(snackbar);
  // Remove after 10 seconds
  setTimeout(function(){
    snackbar.remove();
  }, 5000);
}
