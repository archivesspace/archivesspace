//= require subrecord.crud 
//= require form
//

$(document).on("shown.bs.modal", function() { 
  $('#confirmButton.repo-delete').prop('disabled', true) 
  $('#deleteRepoConfim').on( 'keyup', function() {
    $this = $(this) 
    if ( $this.val() == $this.data('confirm-answer')) {
      $('#confirmButton.repo-delete').prop('disabled', false) 
    } else { 
      $('#confirmButton.repo-delete').prop('disabled', true) 
    }
  })
});
