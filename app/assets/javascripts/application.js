// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery.min
//= require jquery_ujs
//= require jquery-ui.custom.min
//= require jquery-ui-timepicker-addon
//= require bootstrap
//= require bootstrap-fileupload
//= require jquery.tokeninput
//= require jquery.jcarousel
//= require_directory ./base
//= require_tree .


(function ($, tmpst) {
	'use strict';

	/**
	 * Find the related page function and initizlie it
	 */
	$(function () {
		var controller = $('body').data('controller');
		var page = tmpst[tmpst.format('#{0}Page', controller)];

		if (page && tmpst.isFunction(page)) {
			new page();
		}
	});
}(jQuery, tmpst));