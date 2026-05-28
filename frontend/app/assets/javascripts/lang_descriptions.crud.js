//= require representativemembers.js

$(function () {
  $(document).bind('subrecordcreated.aspace', function (event, object_name) {
    if (object_name === 'lang_description') {
      // If this is the first lang_description subrecord, then make sure it's set as primary
      const $langDescriptions = $(
        '#resource_lang_descriptions_, #accession_lang_descriptions_, #digital_object_lang_descriptions_'
      );
      if ($langDescriptions.find('ul').children().length == 1) {
        $langDescriptions.find('.is-representative-toggle').click();
      }
    }
  });
});
