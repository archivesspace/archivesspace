
$(document).ready(function(){
  $('form#import')
    .bind("ajax:beforeSend", function(evt, xhr, settings){
      // var $submitButton = $(this).find('input[name="commit"]');
      // xhr.setRequestHeader('X-CSRF-Token', $("meta[name='csrf-token']").attr('content'));
    })
    .submit(function() {
      
      
      var formData = new FormData();
      formData.append('upload[import_file]', document.getElementById('upload_import_file').files[0]); //Files[0] = 1st file
      formData.append('importer', document.getElementById('importer').value);
      upload(formData);

			$("#import-results").empty();
      return false;
    });     
});


function upload(formData) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', '/import/upload_xhr', true);

  var cursor = new ResponseCursor();
	var emitter = new StandardResultEmitter();
  
  xhr.addEventListener("progress", function(evt){
    
    var updates = cursor.read_response(this.response);

		for (i=0; i < updates.length; i++) {
			// send normalized update to the shared inline script
			handleUpdate(updates[i], emitter);
		}
  }, false);
  
  xhr.addEventListener("load", function(evt){
		$("form#import button.btn-primary").removeClass("disabled").removeClass("busy");
	}, false);
  xhr.send(formData);
}


function StandardResultEmitter() {
	
	this.add_status_row = function(status, bar) {
		bar = bar === 'undefined' ? true : bar;
		var progress = bar ? "<progress value='1' max='100'></progress>" : "";
		$("#import-results").append("<div class='import-results-row alert' id='status-"+status.id+"'><p>"+status.label+":</p>"+progress+"</div>");		
	}
	
	this.refresh_status_message = function(status) {
		$("#status-" + status.id + " p").html(status.label);
	}
	
	this.update_progress = function(ticks, total) {
		$("#import-results progress:last").attr('value', ticks);
	  $("#import-results progress:last").attr('max', total);	
	}
	
	this.add_error_row = function(error) {
		$("#import-results").append("<div class='import-results-row alert alert-error'><p>Error: <pre>"+error+"</pre></p>");
	}
	
	this.show_saved = function(save_count) {
		$("#import-results").append("<div class='import-results-row alert alert-success'><p><b>Saved: "+save_count+" records.</b></p></div>");	
	}

  this.show_links = function(links) {
    $("#import-results").append("<div class='import-results-row alert alert-success'><p>Imported Records: <p><ul class='import-record-links'></ul></div>'");
    var $linkList = $('ul.import-record-links');
    $.each(links, function(i, val) {
      $linkList.append("<li>" + val + "</li>");
    });
  }
}


function ResponseCursor() {
  var _index = 0;
  var response_buffer = "";
  var latest = "";

  this.read_response = function(response_string) {
	  latest = response_string.substring(_index);
    _index = response_string.length;
	
		var buffered = response_buffer + latest;
		var chunked = buffered.split(/---\n/);		
		var updates = [];
		
		for (i = 0; i < chunked.length - 1; i++) {
			updates[i] = JSON.parse(chunked[i]);
		}
				
		resonse_buffer = chunked[chunked.length - 1];
		return updates;
	}  
}




