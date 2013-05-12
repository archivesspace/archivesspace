
$(document).ready(function(){
	$('form#import')
		.bind("ajax:beforeSend", function(evt, xhr, settings){
			var $submitButton = $(this).find('input[name="commit"]');
			$submitButton.text( "Submitting....");		
		})
		.submit(function() {
			var formData = new FormData();
			formData.append('upload[import_file]', document.getElementById('upload_import_file').files[0]); //Files[0] = 1st file
			formData.append('importer', document.getElementById('importer').value);
			upload(formData);

			return false;
			
		});		
});



function upload(formData) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', '/import/upload_xhr', true);
	xhr.addEventListener("progress", statusUpdate, false);
	xhr.addEventListener("load", cleanUp, false);
  xhr.send(formData);
}


function cleanUp(event) {
	$("form#import button.btn-primary").removeClass("disabled").removeClass("busy");
	
}


function statusUpdate(event) {

	console.log(this.response);

	// get the latest update
	var last_index = this.response.lastIndexOf("<div");
	var update = this.response.substring(last_index);

	// get rid of stale updates
	var count = $("#import-results div").length;
	if (count > 5) {
		$("#import-results").children("div:first").remove();
	}
	
	$('#import-results').append(update);
}


