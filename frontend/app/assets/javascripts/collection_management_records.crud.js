//= require subrecord.crud
//= require form


var calculate_total_processing_hours = function(form) { 
    var $form = $(form);
    var phe = parseInt($("#resource_collection_management__processing_hours_per_foot_estimate_", $form).val(), 10);
    var pte = parseInt($("#resource_collection_management__processing_total_extent_", $form).val(), 10);

    if ( $.isNumeric(phe) && $.isNumeric(pte) ) {
        var tph = phe * pte;
        $("#resource_collection_management__processing_hours_total_", $form).val(tph);
    }
}


$(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {

   $("#resource_collection_management__processing_hours_per_foot_estimate_", $(subform)).bind('change', function() { 
        calculate_total_processing_hours( subform ); 
    });
   $("#resource_collection_management__processing_total_extent_", $(subform)).bind('change', function() { 
        calculate_total_processing_hours( subform ); 
    });

})
