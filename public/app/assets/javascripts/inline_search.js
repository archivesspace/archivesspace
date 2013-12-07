$(function() {

  var initSearchNav = function($section) {
    $section.find("a[data-remote='true']").each(function() {
      $(this).bind('ajax:success', function(evt, data, status) {
        $section.children('.inline-results').html(data);
        initSearchNav($section);
      });
    });
  };
    

  $('.search-data-as-subrecord').each(function() {
    initSearchNav($(this));
  });
});
