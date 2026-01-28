function MoreFacets($more_facets_dd) {
  this.$more_facets_dd = $more_facets_dd;

  this.bind_events();
}

MoreFacets.prototype.bind_events = function () {
  var self = this;

  self.$more_facets_dd.find('.more-facets__more').on('click', function (e) {
    const $lessBtn = $(this).siblings('.more-facets__less');
    const $revealedFacets = self.$more_facets_dd.siblings(
      '.more-facets__facets'
    );

    $revealedFacets.show();
    $lessBtn.show();
    $(this).hide();
    $revealedFacets.first().find('a').trigger('focus');
  });

  self.$more_facets_dd.find('.more-facets__less').on('click', function (e) {
    const $moreBtn = $(this).siblings('.more-facets__more');

    self.$more_facets_dd.siblings('.more-facets__facets').hide();
    $(this).hide();
    $moreBtn.show();
    $moreBtn.trigger('focus');
  });
};

$(function () {
  $('.more-facets').each(function () {
    new MoreFacets($(this));
  });
});
