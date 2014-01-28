$(function () {
  // force down embedded image widths for Firefox and IE
  var max_width = $('div.span9').width();
  $('.image-responsive').each(function(i, el){
    if ($(el).width() > max_width) {
      $(el).width(max_width);
    }
  });
});

