# ArchivesSpace Internationalization

ArchivesSpace has abstracted all the labels, messages and tooltips out of the application into the locale files.  The locales in this directory represent the basis of translations for use by all Archives Space applications.  Each application may then add to or override these values with their own locales files.

The base translations are broken up:

  * The top most file "en.yml" contains the translations for all the record labels, messages and tooltips
  * "enums/en.yml" contains the entries for the dynamic enumeration codes - add your translations to this file after importing your enumeration codes

For a guide on managing these "i18n" files, please visit http://guides.rubyonrails.org/i18n.html

## Tooltips

To add a tooltip to a record label, simply add a new entry with "_tooltip" appended to the label's code.  For example, to add a tooltip for the Accession's Title field:

```
en:
  accession:
    title: Title
    title_tooltip: |
        <p>The title assigned to an accession or resource. The accession title
        need not be the same as the resource title. Moreover, a title need not
        be expressed for the accession record, as it can be implicitly
        inherited from the resource record to which the accession is
        linked.</p>
```

## Placeholders

For text fields or textareas, you may like to have some placeholder text to be displayed when the field is empty (for more details see http://www.w3.org/html/wg/drafts/html/master/forms.html#the-placeholder-attribute).  Please note while most modern browser releases support this feature, older version will not.

To add a placeholder to a record's text field, add a new entry of the label's code appened with "_placeholder". For example:


```
en:
  accession:
    title: Title
    title_placeholder: See DACS 2.3.18-2.3.22
```