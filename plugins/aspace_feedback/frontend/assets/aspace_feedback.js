$(function() {

  var $link = $("#aspaceFeedbackLink");

  $link.click(function() {
    var $feedbackForm = $(AS.renderTemplate("template_feedback_form"));

    AS.openCustomModal("aspaceFeedbackModal", $link.text(), $feedbackForm, "container", {}, $link);
  });

});