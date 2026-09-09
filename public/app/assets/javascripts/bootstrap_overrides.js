// Bootstrap can leave focus inside a modal while applying aria-hidden when hiding the modal,
// causing an accessibility warning (focused element inside aria-hidden).
// Toggle inert around the hide/show lifecycle so focus cannot remain in the modal while being hidden.
// This issue is solved in Bootstrap v6 by using the <dialog> element :)
// See: https://github.com/twbs/bootstrap/issues/41005
$(document).on('hide.bs.modal', event => {
  event.target.inert = true;
});

$(document).on('show.bs.modal', event => {
  event.target.inert = false;
});
