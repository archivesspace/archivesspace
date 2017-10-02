ArchivesSpace Assessment CSV Import Template 
--------------------------------------------

[Download](https://raw.githubusercontent.com/archivesspace/archivesspace/master/backend/app/exporters/examples/assessment/aspace_assessment_import_template.csv)

Use this CSV template for importing Assessment data into ArchivesSpace. 

The first two rows define the column headers. The order of the columns doesn't matter.

The first row specifies the section that the column belongs to.
Valid values are: basic, rating, format and conservation.

The second row specifies the field within the section for that column.

The 'basic' columns are fixed fields on the assessment record.

In the 'basic' section, 'record', 'surveyed_by' and 'reviewer' are repeating fields.
Simply add enough of these columns for the assessment record that has the most
linked records, surveyors or reviewers, then
leave the surplus columns blank for rows that have fewer.

The 'basic', 'record' columns should contain references to existing archival records in
the current repository. They must be of type resource, archival_object, accession or digital_object.

The reference must take the form: type_id.

It is also permitted to use '/', '.' or space, in place of the '_'. For example, the following
are valid record references (assuming the corresponding records exist in the current repository):

    resource_12
    accession/5
    archival_object 2970

The 'basic', 'surveyed_by' and 'reviewer'  columns must contain usernames of existing users
in the ArchivesSpace instance.

The fields for other sections refer to attribute definitions.
The importer will attempt to match the field value against a definition.
For example: 'format', 'Film' will match the 'Film (negative, slide, or motion picture)' definition.

If it can't find a matching definition, or if more than one definition matches, the importer
will abort and report the problem.

The template has columns for all of the default attribute definitions. It is possible to
add repository specific definitions through the management interface. To import into
these attributes, simply add columns to your CSV. For example, if your repository has
defined an assessment rating called "Comedic Value", add a column to your CSV with 'rating'
in the first row, and 'Comedic Value' in the second.

'rating' type definitions support an associated note field. To import into this field
the field must end with '_note'. In the example above, add another column with 'rating'
in the first row, and 'Comedic Value_note' in the second.
