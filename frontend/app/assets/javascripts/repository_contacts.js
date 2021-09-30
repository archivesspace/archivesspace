// show at least one agent contact record if none are visible
// this provides a fallback where there is no representative contact
$(document).ready(function () {
  var contacts_selector = '#agent_contact .subrecord-form-fields';
  var visible_contacts_selector = contacts_selector + ' :visible';
  if ($(visible_contacts_selector).length === 0) {
    $(contacts_selector).first().removeAttr('style');
  }
});
