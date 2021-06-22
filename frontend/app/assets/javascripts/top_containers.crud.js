//= require space_calculator

$(document).ready(function() {
    $(".linker:not(.initialised)").linker();
    $(document).triggerHandler("loadedrecordform.aspace", [$("#new_top_container_form")]);
});

