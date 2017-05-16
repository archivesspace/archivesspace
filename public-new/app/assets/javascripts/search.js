//= require largetree
//= require tree_renderer

/* search form javascript support */

var $template, $as;
var plusText = 'Add a search row';
var minusText = 'Remove the row below';
var fn_plusminus = function(e){
    e.stopPropagation;
    if ($(this).text() === '+') {
	$(this).text('-');
	$(this).attr('title', minusText);
	var $row = new_row_from_template();
	$(this).parents('.search_row').after($row);
	$row.find(".bool select").focus();
    }
    else {
	$(this).parents(".search_row").next(".search_row").remove();
	$(this).text('+');
	$(this).attr('title', plusText);
    }
    return false;
}

function initialize_search() {
    $as = $("#advanced_search");
    /* create the + button, attach click event */
    new_button($($as.find("#search_row_0"))); 
    /* then save the first_row, so we don't always have to find it */
    var $first = $($as.find("#search_row_0"));
    $template = $first.clone();
    $template.find(".norepeat").each(function() { $(this).empty(); });
    $template.find(".hidden").each(function() {$(this).removeClass("hidden"); });
    $template.find("#op0").removeProp("disabled"); /* the disabled boolean operator */
    $template.find("#op_").remove(); 
    $first.find("#q0").keypress(function (e) {
	    var key = e.which;
	    if (key == 13) {
		$("#submit_search").click();
		return false;
	    }
	});
    return true;
}       

function new_button($row) {
    var $plus = $row.find(".plusminus");
    $plus.html("<button title='" + plusText + "'>+</button>");
    $plus.find("button").click(fn_plusminus);
    return true;
}

function new_row_from_template() {
    var num = $as.find(".search_row").size();
    var $row = $template.clone();
    replace_id_ref($row, 'label', 'for', num);
    replace_id_ref($row, 'input', 'id', num);
    replace_id_ref($row, 'select', 'id', num);
    $row.attr("id", "search_row_" + num);
    new_button($row);
    return $row;
}

function add_search_line() {
    $row = new_row_from_template();

}

function replace_id_ref($row, selector, type, num) {
    $row.find(selector).each(function() {
            $(this).attr(type, $(this).attr(type).replace('0', num));
	});
}

// show subgroups within search results on demand
function toggle_subgroups(event) {
    var $button = $(this);
    var $result = $button.closest('.recordrow');
    var $container = $result.find('.classification-subgroups');
    var $tree = $result.find('.classification-subgroups-tree');

    if ($tree.is(':visible')) {
        $tree.hide();
        $button.attr('aria-pressed', 'false').removeClass('active');
        $button.find('.fa').removeClass('fa-minus').addClass('fa-plus');
    } else {
        $tree.show();

        if ($tree.is(':empty')) {
            var root_uri = $result.data('uri');
            var should_link_to_record = true;

            var tree = new LargeTree(new TreeDataSource(root_uri + '/tree'),
                $tree,
                root_uri,
                true,
                new SimpleRenderer(should_link_to_record),
                $.noop,
                $.noop);
        }

        $button.attr('aria-pressed', 'true').addClass('active');
        $button.find('.fa').removeClass('fa-plus').addClass('fa-minus');
    }
};

$(function() {
    $('.search-results').on('click',
        '.recordrow .classification-subgroups button.subgroup-toggle',
        toggle_subgroups);
});
