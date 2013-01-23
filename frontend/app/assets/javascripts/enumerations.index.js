$(function() {

  var handleEnumNameChange = function(event) {
    document.location.search = "?enum_name="+$(this).val()
  };

  $("#enum_selector").change(handleEnumNameChange);

});
