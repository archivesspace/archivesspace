function MoreFacets($more_facets_div) {
  this.$more_facets_div = $more_facets_div;

  this.bind_events();
}

MoreFacets.prototype.bind_events = function () {
  var self = this;

  self.$more_facets_div.find('.more-facets__more').on('click', function (e) {
    $(this).siblings('.more-facets__facets').show();
    $(this).siblings('.more-facets__less').show();
    $(this).hide();
  });

  self.$more_facets_div.find('.more-facets__less').on('click', function (e) {
    $(this).siblings('.more-facets__facets').hide();
    $(this).hide();
    $(this).siblings('.more-facets__more').show();
  });
};

$(function () {
  $('.more-facets').each(function () {
    new MoreFacets($(this));
  });
});
