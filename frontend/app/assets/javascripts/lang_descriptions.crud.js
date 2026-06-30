//= require representativemembers.js

$(function () {
  $(document).bind('subrecordcreated.aspace', function (event, object_name) {
    if (object_name === 'lang_description') {
      // If this is the first lang_description subrecord, then make sure it's set as primary
      const langDescriptions = document.querySelector(
        '#resource_lang_descriptions_, #accession_lang_descriptions_, #digital_object_lang_descriptions_'
      );
      const ul = langDescriptions.querySelector('ul');
      if (ul.children.length === 1) {
        const toggle = langDescriptions.querySelector(
          '.is-representative-toggle'
        );
        const isPrimary = langDescriptions.querySelector(
          'input[id$="_is_primary_"]'
        );
        const alreadyPrimary = isPrimary?.value === '1';

        if (toggle && !alreadyPrimary) {
          toggle.click();
        }
      }
    }
  });
});
