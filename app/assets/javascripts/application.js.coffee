# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.

# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.

# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.

# Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.

//= require jquery-2.1.3.min
//= require jquery_ujs
//= require bootstrap-sprockets
//= require typeahead
//= require ripple
//= require globals
//= require stripe
//= require select2
//= require ckeditor-jquery


# Invoke globally in application (not on public site!)

$(window).resize ->
  Ripple.adjustElementsForWidth()

$(document).on('ready', ->
  Ripple.adjustWhenTokenized()
  Ripple.adjustElementsForWidth()
)
