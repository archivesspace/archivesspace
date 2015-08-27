AS.initTooManySubRecords = function($containerForm, numberOfSubRecords, callback ) {
      
  if ( numberOfSubRecords > 4 ) {
    var $tooManyMsgEl = $(AS.renderTemplate("too_many_subrecords_template"));                                                                                                   
    $tooManyMsgEl.hide();                                                                                                                                                       
    $containerForm.append($tooManyMsgEl);                                                                                                                                                
    $tooManyMsgEl.fadeIn();                                                                                                                                                     
    $('.subrecord-form-container', $containerForm).hide();                                                                                                                              
     
    $containerForm.addClass("too-many");                                                                                                                                               
    // let's disable the buttons
    $('.subrecord-form-heading .btn', $containerForm).prop('disabled', true);

    $($containerForm).on("click", function(event) {                                                                                                                                     
      event.preventDefault();                                                                                                                                                
      $containerForm.children().andSelf().removeClass("too-many");                                                                                                                                        
      $tooManyMsgEl.html("<i class='spinner'></i>"); 
      $('.subrecord-form-heading .btn', $containerForm).prop('disabled', false);
     
      // give it at least a second before trying ( and maybe dying.. ) 
      setTimeout( function(){  
        callback(function() {  
          $tooManyMsgEl.remove(); 
          $('.subrecord-form-container', $containerForm).fadeIn();                                                                                                                              
          $(document).trigger("loadedrecordsubforms.aspace", $containerForm);
        });
      }, 1000); 
      
      $containerForm.unbind( event );
    });
    return true;
  } else {
    return false;
  }


};
