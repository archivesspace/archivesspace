//= require form
$(function() {
  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if ( object_name === 'container_location' ){
      $("[id$=__status_]", subform ).bind("change", function() {
        $this = $(this);
        $endDate = $("[id$=__end_date_]", subform );
        if ( $this.val() == 'previous' && $endDate.val().length == 0 ) {
          $endDate.val( $endDate.data('date') );
        }
      });
    }
  });
});
