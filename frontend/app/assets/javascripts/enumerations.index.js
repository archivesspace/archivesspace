$(function() {

  var handleEnumNameChange = function(event) {
    document.location.search = "?id="+$(this).val()
  };

  $("#enum_selector").change(handleEnumNameChange);

});
