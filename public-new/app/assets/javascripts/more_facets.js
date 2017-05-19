function MoreFacets($more_facets_div) {
    this.$more_facets_div = $more_facets_div;

    this.bind_events();
};

MoreFacets.prototype.bind_events = function() {
    var self = this;

    self.$more_facets_div.find('.more').on('click', function (e) {
        $(this).siblings('.below-the-fold').show();
        $(this).hide();
    });

    self.$more_facets_div.find('.less').on('click', function (e) {
	    $(this).parent().hide();
	    $(this).parent().parent().find('.more').show();
    });

};

$(function() {
    $('.more-facets').each(function() {
        new MoreFacets($(this));
    });
});