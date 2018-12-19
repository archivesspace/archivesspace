---
title: Customizing text in ArchivesSpace
layout: en
permalink: /user/customizing-text-in-archivesspace/
---
ArchivesSpace has abstracted all the labels, messages and tooltips out of the
application into the locale files, which are part of the
[Rails Internationalization (I18n)](http://guides.rubyonrails.org/i18n.html) API.
The locales in this directory represent the
basis of translations for use by all Archives Space applications.  Each
application may then add to or override these values with their own locales files.

For a guide on managing these "i18n" files, please visit http://guides.rubyonrails.org/i18n.html

You can see the source files for both the [Staff Frontend Application](https://github.com/archivesspace/archivesspace/tree/master/frontend/config/locales) and
[Public Application](https://github.com/archivesspace/archivesspace/tree/master/public/config/locales). There is also a [common locale file](https://github.com/archivesspace/archivesspace/blob/master/common/locales/en.yml) for some values used throughout the ArchivesSpace applications.

The base translations are broken up:

  * The top most file "en.yml" contains the translations for all the record labels, messages and tooltips in English
  * "enums/en.yml" contains the entries for the dynamic enumeration codes - add your translations to this file after importing your enumeration codes

These values are pulled into the views using the I18n.t() method, like  I18n.t("brand.welcome_message").

If the value you want to override is in the common locale file (like the "digital object title" field label, for example) , you can change this by simply editing the locales/en.yml file in your ArchivesSpace distribution home directory. A restart is required to have the changes take effect.  

If the value you want to change is in either the public or staff specific en.yml files,  you can override these values using the plugins directory. For example, if you want to change the welcome message on the public frontend, make a file in your ArchivesSpace distribution called 'plugins/local/public/locales/en.yml' and put the following values:

	en:
		brand:
		title: My Archive
		home: Home
 		welcome_message: HEY HEY HEY!!

If you restart ArchivesSpace, these values will take effect.

If you're using a different language, simply swap out the en.yml for something else ( like fr.yml ) and update locale setting in the config.rb file ( i.e.,  AppConfig[:locale] = :fr )

## Tooltips

To add a tooltip to a record label, simply add a new entry with "\_tooltip"
appended to the label's code.  For example, to add a tooltip for the Accession's
Title field:

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

For text fields or text areas, you may like to have some placeholder text to be
displayed when the field is empty (for more details see
http://www.w3.org/html/wg/drafts/html/master/forms.html#the-placeholder-attribute).
Please note while most modern browser releases support this feature,
older version will not.

To add a placeholder to a record's text field, add a new entry of the label's
code append with "\_placeholder". For example:


```
en:
  accession:
    title: Title
    title_placeholder: See DACS 2.3.18-2.3.22
```
