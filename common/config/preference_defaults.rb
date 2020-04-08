# The contents of the hash declared below will be loaded into the global preferences
# record at system start-up. This has the effect of setting defaults for user preferences.
# Only keys matching propoerties declared in common/schemas/defaults.rb will be loaded.
# TAKE CARE editing this file as errors will prevent the system from starting.
{
  'show_suppressed' => false,
  'publish' => false,
  'locale' => AppConfig[:locale].to_s,
  'accession_browse_column_1' => 'identifier',
  'accession_browse_column_2' => '',
  'accession_browse_column_3' => '',
  'accession_browse_column_4' => '',
  'accession_browse_column_5' => '',
  'resource_browse_column_1' => 'identifier',
  'resource_browse_column_2' => '',
  'resource_browse_column_3' => '',
  'resource_browse_column_4' => '',
  'resource_browse_column_5' => '',
  'digital_object_browse_column_1' => '',
  'digital_object_browse_column_2' => '',
  'digital_object_browse_column_3' => '',
  'digital_object_browse_column_4' => '',
  'digital_object_browse_column_5' => '',
  'note_order' => [],
}
