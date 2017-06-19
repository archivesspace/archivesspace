/* handle the accordions */
/* we need to pass in the text that is obtained via the config/locales/*yml file */
var expand_text = "";
var collapse_text = "";
/* we don't provide a button if there's only one panel; neither do we collapse that one panel */
function initialize_accordion(what, ex_text, col_text) {
    expand_text = ex_text;
    collapse_text = col_text;
    if ($(what).size() > 1 && $(what).parents(".acc_holder").size() ===1 ) {
	if ($(what).parents(".acc_holder").children(".acc_button").size() == 0) {
	    $(what).parents(".acc_holder").prepend("<a  class='btn btn-primary btn-sm acc_button' role='button' ></a>");
	}
	collapse_all(what, false);
    }
}
function collapse_all(what, expand) {
    $(what).each(function() { $(this).collapse(((expand)? "show" : "hide")); } );
    set_button(what, !expand);
}

function set_button(what, expand) {
    $holder = $(what).parents(".acc_holder");
    $btn = $holder.children('.acc_button');
    if ($btn.size() === 1) {
	$btn.text((expand)?expand_text : collapse_text);
	$btn.attr("href", "javascript:collapse_all('" + what + "'," + expand +")");
    }
}