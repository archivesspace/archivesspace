This plugin adds automatic identifier generation to the "Create
Accession" form.  The form will default to an identifier such as:

  YYYY NNN

Where YYYY is the current year, and NNN is a sequence number.

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     AppConfig[:plugins] = ['generate-accession-identifiers-plugin']
