var statusIndex = 0;
var progressTotal = 0;
var partialMessage = "";


$(document).ready(function(){
	$('form#import')
		.bind("ajax:beforeSend", function(evt, xhr, settings){
			var $submitButton = $(this).find('input[name="commit"]');
			$submitButton.text( "Submitting....");
			// xhr.setRequestHeader('X-CSRF-Token', $("meta[name='csrf-token']").attr('content'));
		})
		.submit(function() {
			
			statusIndex = 0;
			progressTotal = 0;
			partialMessage = "";
			
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

	var response = this.response;

	
	if (response.length > statusIndex) {
		var latest = response.substring(statusIndex);		
		statusIndex = response.length;
	}

	var k = latest.indexOf("---");
	if (k < 0){
		partialMessage = partialMessage + latest;
	} else {
		var message = partialMessage + latest.substring(0,k);
		
		console.log(message);

		var update = $.parseJSON(message);

		console.log(update);
		
		handleUpdate(update);
		
	}
	

}

function handleUpdate(updateObject) {
	if (updateObject.status) {
		refreshStatus(updateObject.status);
	}
	
	if (updateObject.errors) {
		showErrors(updateObject.errors);
	}	
	
	if (updateObject.total) {
		var newTotal = updateObject.total;
		if (newTotal != progressTotal){
			progressTotal = newTotal;
			$("#import-results progress:last").attr('max', progressTotal);
		}		
	}
	
	if (updateObject.ticks) {
		var ticks = updateObject.ticks;
		$("#import-results progress:last").attr('value', ticks);
	}
	
	if (updateObject.saved) {
		console.log("TRUE");
		var saved = updateObject.saved;
		rowhtml = "<div class='import-results-row'><p><b>Saved " + saved.length + " records.</b></p></div>"	
		$('#import-results').append(rowhtml)

	}
	
}



function refreshStatus(statusArray) {
	for (var i = 0; i < statusArray.length; i++) {
		var status = statusArray[i];
		if (status.type == 'started') {
			rowhtml = "<div class='import-results-row' id='status-" + status.id + "'><p>" + status.label + ":</p><progress value='5' max='100'></progress></div>"

			$('#import-results').append(rowhtml)
			
		} else if (status.type == 'done') {	
			var max = $("#status-"+status.id + " progress").attr('max');
			$("#status-"+status.id + " progress").attr('value', max);
		}
		
	}
}

function showErrors(errorArray) {
	for (var i = 0; i < errorArray.length; i++) {
		$("#import-results progress:last").remove();
		$('#import-results').append("<p><b>Error: " + errorArray[i] + "</b></p>");
	}
}


