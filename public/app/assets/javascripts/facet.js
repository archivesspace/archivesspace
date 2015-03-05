$(function() {

  // show top 10 facet results with link to display more / fewer
  $('.facet').each( function() {
    var list = this;
    $(list).children('li:gt(9)').hide().last().after(
      $('<a />').attr('href','#').attr('class', 'show_more').text(FACET_SHOW_MORE).click(function() {
        if($('.show_fewer:not(:visible)')) $('.show_fewer').show();
        $(list).children('li:not(:visible):lt(10)').fadeIn(function() {
          if ($(list).children('li:not(:visible)').length == 0) {
            $('.show_more').hide();
            $('span.show_fewer').hide();
          }
        }); return false;
      }),
      $('<span class="show_fewer"> -- </span>').hide(),
      $('<a />').attr('href','#').attr('class', 'show_fewer').text(FACET_SHOW_FEWER).click(function() {
        if ($('.show_more:not(:visible)')) $('.show_more').show();
        $(list).children('li:visible:gt(9)').fadeOut(function() {
          if ($(list).children('li:visible').length == 10) $('.show_fewer').hide();
        }); return false;
      }).hide()
    );
  });

});