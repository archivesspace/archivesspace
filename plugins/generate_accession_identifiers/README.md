This plugin adds automatic identifier generation to the "Create
Accession" form.  The form will default to an identifier such as:

  YYYY NNN

Where YYYY is the current year, and NNN is a sequence number.

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     AppConfig[:plugins] = ['generate_accession_identifiers']

By default, numbering will start at zero (so in 2018, the first
identifier issued will be 2018-000).  You can set the starting number
with a MySQL update if desired:

     -- Substitute 2018 for the current year and 20000 for whatever
     -- starting value you would like.  In this example, the first
     -- identifier given out will be '2018-20001'.
     --
     REPLACE INTO sequence (sequence_name, value) VALUES ('GENERATE_ACCESSION_IDENTIFIER_2018', 20000);
