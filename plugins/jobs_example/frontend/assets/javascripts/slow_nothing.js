// In this example we disable the 'how many times' input when 'do more than once' is not selected 
$(function() {
	$("#job_multiple_").change(function() {
		if (this.checked) {
			$("#job_times_").closest(".form-group").show();
			$("#job_times_").val(null);
		} else {
			$("#job_times_").closest(".form-group").hide();
			$("#job_times_").val(1);
		}
	});
	$("#job_multiple_").triggerHandler("change");
});
