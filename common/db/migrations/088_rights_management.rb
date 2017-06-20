require 'securerandom'
require 'json'


def backup_rights_statement_table
  create_table(:rights_statement_pre_088, :as => self[:rights_statement])
end


def create_rights_statement_act
  create_table(:rights_statement_act) do
    primary_key :id

    Integer :rights_statement_id, :null => false
    DynamicEnum :act_type_id, :null => false
    DynamicEnum :restriction_id, :null => false
    Date :start_date, :null => false
    Date :end_date, :null => true

    apply_mtime_columns
  end

  alter_table(:rights_statement_act) do
    add_foreign_key([:rights_statement_id], :rights_statement, :key => :id)
  end

  create_editable_enum("rights_statement_act_type",
                       ['delete', 'disseminate', 'migrate', 'modify', 'replicate', 'use'])

  create_editable_enum("rights_statement_act_restriction",
                       ['allow', 'disallow', 'conditional'])
end


def link_acts_to_notes
  alter_table(:note) do
    add_column(:rights_statement_act_id, Integer,  :null => true)
    add_foreign_key([:rights_statement_act_id], :rights_statement_act, :key => :id)
  end

  create_enum("note_rights_statement_act_type",
              ['permissions', 'restrictions', 'extension', 'expiration', 'additional_information'])

end


def link_rights_statements_to_agents
  alter_table(:linked_agents_rlshp) do
    add_column(:rights_statement_id, Integer,  :null => true)
    add_foreign_key([:rights_statement_id], :rights_statement, :key => :id)
  end
end


def link_rights_statements_to_notes
  alter_table(:note) do
    add_column(:rights_statement_id, Integer,  :null => true)
    add_foreign_key([:rights_statement_id], :rights_statement, :key => :id)
  end

  create_enum("note_rights_statement_type",
              ['materials', 'type_note', 'additional_information'])

end


def add_identifier_type_to_external_documents
  alter_table(:external_document) do
    add_column(:identifier_type_id, Integer, :null => true)
    add_foreign_key([:identifier_type_id], :enumeration_value, :key => :id, :name => 'external_document_identifier_type_id_fk')
  end

  create_editable_enum('rights_statement_external_document_identifier_type',
                       [ 'agrovoc',
                                'allmovie',
                                'allmusic',
                                'allocine',
                                'amnbo',
                                'ansi',
                                'artsy',
                                'bdusc',
                                'bfi',
                                'bnfcg',
                                'cantic',
                                'cgndb',
                                'danacode',
                                'datoses',
                                'discogs',
                                'dkfilm',
                                'doi',
                                'ean',
                                'eidr',
                                'fast',
                                'filmport',
                                'findagr',
                                'freebase',
                                'gec',
                                'geogndb',
                                'geonames',
                                'gettytgn',
                                'gettyulan',
                                'gnd',
                                'gnis',
                                'gtin-14',
                                'hdl',
                                'ibdb',
                                'idref',
                                'imdb',
                                'isan',
                                'isbn',
                                'isbn-a',
                                'isbnre',
                                'isil',
                                'ismn',
                                'isni',
                                'iso',
                                'isrc',
                                'issn',
                                'issn-l',
                                'issue-number',
                                'istc',
                                'iswc',
                                'itar',
                                'kinopo',
                                'lccn',
                                'lcmd',
                                'lcmpt',
                                'libaus',
                                'local',
                                'matrix-number',
                                'moma',
                                'munzing',
                                'music-plate',
                                'music-publisher',
                                'musicb',
                                'natgazfid',
                                'nga',
                                'nipo',
                                'nndb',
                                'npg',
                                'odnb',
                                'opensm',
                                'orcid',
                                'oxforddnb',
                                'porthu',
                                'rbmsbt',
                                'rbmsgt',
                                'rbmspe',
                                'rbmsppe',
                                'rbmspt',
                                'rbmsrd',
                                'rbmste',
                                'rid',
                                'rkda',
                                'saam',
                                'scholaru',
                                'scope',
                                'scopus',
                                'sici',
                                'spotify',
                                'sprfbsb',
                                'sprfbsk',
                                'sprfcbb',
                                'sprfcfb',
                                'sprfhoc',
                                'sprfoly',
                                'sprfpfb',
                                'stock-number',
                                'strn',
                                'svfilm',
                                'tatearid',
                                'theatr',
                                'trove',
                                'upc',
                                'uri',
                                'urn',
                                'viaf',
                                'videorecording-identifier',
                                'wikidata',
                                'wndla'])

  # Default identifier type to 'local' for any rights statement
  # external documents
  enum_local_id = self[:enumeration_value]
                     .filter(:enumeration_id => self[:enumeration]
                                                  .filter(:name => 'rights_statement_external_document_identifier_type')
                                                  .select(:id))
                     .filter(:value => 'local')
                     .select(:id)
                     .first[:id]

  self[:external_document]
    .filter(Sequel.~(:rights_statement_id => nil))
    .update(:identifier_type_id => enum_local_id)
end


def add_new_rights_statement_columns
  alter_table(:rights_statement) do
    add_column(:status_id, Integer,  :null => true)
    add_column(:start_date, Date, :null => true)
    add_column(:end_date, Date, :null => true)
    add_column(:determination_date, Date, :null => true)
    add_column(:license_terms, String, :null => true)
    add_column(:other_rights_basis_id, Integer, :null => true)

    add_foreign_key([:status_id], :enumeration_value, :key => :id, :name => 'rights_statement_status_id_fk')
    add_foreign_key([:other_rights_basis_id], :enumeration_value, :key => :id, :name => 'rights_statement_other_rights_basis_id_fk')
  end

  create_editable_enum('rights_statement_other_rights_basis',
                       ['donor', 'policy'])
end


# - Populate a meaningful start_date for rights statements
def migrate_rights_statement_start_date
  self[:rights_statement]
    .filter(Sequel.~(:restriction_start_date => nil))
    .update(:start_date => :restriction_start_date)

  # - Ensure all rights statements have a start_date

  # For accessions use the accession_date
  self[:accession]
    .left_outer_join(:rights_statement, :rights_statement__accession_id => :accession__id)
    .filter(:rights_statement__start_date => nil)
    .select(Sequel.as(:rights_statement__id, :rights_statement_id),
            Sequel.as(:accession__accession_date, :accession_date))
    .order(:rights_statement__id)
    .each do |row|

    next if row[:rights_statement_id].nil?

    self[:rights_statement]
      .filter(:id => row[:rights_statement_id])
      .update(:start_date => row[:accession_date])
  end

  # For resources or archival objects
  # take the begin from a 'creation' date and fallback to the 
  # creation timestamp
  ['resource', 'archival_object'].each do |record_type|
    last_rights_statement_id = nil
    # find a date with a 'begin' date
    self[:"#{record_type}"]
      .left_outer_join(:rights_statement, :"rights_statement__#{record_type}_id" => :"#{record_type}__id")
      .left_outer_join(:date, :"date__#{record_type}_id" => :"#{record_type}__id")
      .filter(:rights_statement__start_date => nil)
      .filter(Sequel.~(:date__begin => nil))
      .filter(:date__label_id => self[:enumeration_value]
                                   .filter(:value => 'creation')
                                   .filter(:enumeration_id => self[:enumeration]
                                                                .filter(:name => 'date_label')
                                                                .select(:id))
                                   .select(:id))
      .select(Sequel.as(:rights_statement__id, :rights_statement_id),
              Sequel.as(:date__begin, :begin))
      .order(:rights_statement__id)
      .each do |row|

      next if last_rights_statement_id == row[:rights_statement_id] || row[:rights_statement_id].nil?

      start_date = coerce_date(row[:begin])

      self[:rights_statement]
        .filter(:id => row[:rights_statement_id])
        .update(:start_date => start_date)

      last_rights_statement_id = row[:rights_statement_id]
    end

    # fallback to the create timestamp
    self[:"#{record_type}"]
      .left_outer_join(:rights_statement, :"rights_statement__#{record_type}_id" => :"#{record_type}__id")
      .filter(:rights_statement__start_date => nil)
      .select(Sequel.as(:rights_statement__id, :rights_statement_id),
              Sequel.as(:"#{record_type}__create_time", :create_time))
      .order(:rights_statement__id)
      .each do |row|

      next if row[:rights_statement_id].nil?

      start_date = coerce_timestamp(row[:create_time])

      self[:rights_statement]
        .filter(:id => row[:rights_statement_id])
        .update(:start_date => start_date)
    end
  end
end


# - Rights types coded as "Intellectual Property" should be converted to
#   "Copyright", and Rights types coded as "Institutional Policy"
#   should be converted to "Other".
def migrate_rights_statement_types
  @rights_type_enum_id = self[:enumeration]
                           .filter(:name => 'rights_statement_rights_type')
                           .select(:id)

  self[:enumeration_value]
    .filter(:enumeration_id => @rights_type_enum_id)
    .filter(:value => 'intellectual_property')
    .update(:value => 'copyright')

  self[:enumeration_value]
    .filter(:enumeration_id => @rights_type_enum_id)
    .filter(:value => 'institutional_policy')
    .update(:value => 'other')
end

# - Order Rights Type enums as follows
#   'Copyright', 'License', 'Statute', 'Other'
def reorder_rights_statement_types
  # pump up order to avoid unique constraints
  ['copyright', 'license', 'statute', 'other'].each_with_index do |type, i|
    self[:enumeration_value]
      .filter(:enumeration_id => @rights_type_enum_id)
      .filter(:value => type)
      .update(:position => 10000 + i)
  end

  # now apply the correct order
  ['copyright', 'license', 'statute', 'other'].each_with_index do |type, i|
    self[:enumeration_value]
      .filter(:enumeration_id => @rights_type_enum_id)
      .filter(:value => type)
      .update(:position => i)
  end

end


# Copy ip_status_id into status_id
def migrate_ip_status
  self[:rights_statement]
    .filter(Sequel.~(:ip_status_id => nil))
    .update(:status_id => :ip_status_id)
end


# - Migrate data currently encoded in "IP Expiration Date" on the
#   "Intellectual Property" template to "End Date" on the Copyright
#   template
def migrate_ip_expiration_date
  self[:rights_statement]
    .filter(Sequel.~(:ip_expiration_date => nil))
    .update(:end_date => :ip_expiration_date)
end


#  - When a rights type is converted from "Institutional Policy" to
#    "Other", the "Other Rights Basis" value should be "Institutional
#    Policy"
def migrate_other_rights_basis
  other_rights_basis_enum = self[:enumeration]
                              .filter(:name => 'rights_statement_other_rights_basis')
                              .select(:id)
  policy_enum_id = self[:enumeration_value]
                     .filter(:enumeration_id => other_rights_basis_enum)
                     .filter(:value => 'policy')
                     .select(:id)
  other_type_id = self[:enumeration_value]
                    .filter(:enumeration_id => @rights_type_enum_id)
                    .filter(:value => 'other')
                    .select(:id)
  self[:rights_statement]
    .filter(:rights_type_id => other_type_id)
    .update(:other_rights_basis_id => policy_enum_id)
end


# - All data currently included in the "Materials" element should be
#   migrated to the note with the label "Materials".
def migrate_materials_to_note
  self[:rights_statement]
    .filter(Sequel.~(:materials => nil))
    .select(:id, :materials, :last_modified_by, :create_time, :system_mtime, :user_mtime)
    .each do |row|
    self[:note].insert(
      :rights_statement_id => row[:id],
      :publish => 1,
      :notes_json_schema_version => 1,
      :notes => blobify(self, JSON.generate({
                                  'jsonmodel_type' => 'note_rights_statement',
                                  'content' => [row[:materials]],
                                  'type' => 'materials',
                                  'persistent_id' => SecureRandom.hex
                                })),
      :last_modified_by => row[:last_modified_by],
      :create_time => row[:create_time],
      :system_mtime => row[:system_mtime],
      :user_mtime => row[:user_mtime]
    )
  end
end


# - Also, all data currently included in the "Type" note should be
# migrated to the note with the label "Type".
def migrate_type_to_note
  self[:rights_statement]
    .filter(Sequel.~(:type_note => nil))
    .select(:id, :type_note, :last_modified_by, :create_time, :system_mtime, :user_mtime)
    .each do |row|
    self[:note].insert(
      :rights_statement_id => row[:id],
      :publish => 1,
      :notes_json_schema_version => 1,
      :notes => blobify(self, JSON.generate({
                                  'jsonmodel_type' => 'note_rights_statement',
                                  'content' => [row[:type_note]],
                                  'type' => 'type_note',
                                  'persistent_id' => SecureRandom.hex
                                })),
      :last_modified_by => row[:last_modified_by],
      :create_time => row[:create_time],
      :system_mtime => row[:system_mtime],
      :user_mtime => row[:user_mtime]
    )
  end
end


# - Migrate data currently encoded in "Permissions" to a Rights Statement note
#   with type 'Additional Information' and label 'Permissions'
def migrate_permissions_to_note
  self[:rights_statement]
    .filter(Sequel.~(:permissions => nil))
    .select(:id, :permissions, :last_modified_by, :create_time, :system_mtime, :user_mtime)
    .each do |row|
    self[:note].insert(
      :rights_statement_id => row[:id],
      :publish => 1,
      :notes_json_schema_version => 1,
      :notes => blobify(self, JSON.generate({
                                  'jsonmodel_type' => 'note_rights_statement',
                                  'content' => [row[:permissions]],
                                  'type' => 'additional_information',
                                  'label' => 'Permissions',
                                  'persistent_id' => SecureRandom.hex
                                })),
      :last_modified_by => row[:last_modified_by],
      :create_time => row[:create_time],
      :system_mtime => row[:system_mtime],
      :user_mtime => row[:user_mtime]
    )
  end
end


# - Migrate data currently encoded in "Restrictions" to a Rights Statement note
#   with type 'Additional Information' and label 'Restrictions'
def migrate_restrictions_to_note
  self[:rights_statement]
    .filter(Sequel.~(:restrictions => nil))
    .select(:id, :restrictions, :last_modified_by, :create_time, :system_mtime, :user_mtime)
    .each do |row|
    self[:note].insert(
      :rights_statement_id => row[:id],
      :publish => 1,
      :notes_json_schema_version => 1,
      :notes => blobify(self, JSON.generate({
                                  'jsonmodel_type' => 'note_rights_statement',
                                  'content' => [row[:restrictions]],
                                  'type' => 'additional_information',
                                  'label' => 'Restrictions',
                                  'persistent_id' => SecureRandom.hex
                                })),
      :last_modified_by => row[:last_modified_by],
      :create_time => row[:create_time],
      :system_mtime => row[:system_mtime],
      :user_mtime => row[:user_mtime]
    )
  end
end


# - Migrate data currently encoded in "Granted Note" to a Rights Statement note
#   with type 'Additional Information' and label 'Granted Note' 
def migrate_granted_note_to_note
  self[:rights_statement]
    .filter(Sequel.~(:granted_note => nil))
    .select(:id, :granted_note, :last_modified_by, :create_time, :system_mtime, :user_mtime)
    .each do |row|
    self[:note].insert(
      :rights_statement_id => row[:id],
      :publish => 1,
      :notes_json_schema_version => 1,
      :notes => blobify(self, JSON.generate({
                                  'jsonmodel_type' => 'note_rights_statement',
                                  'content' => [row[:granted_note]],
                                  'type' => 'additional_information',
                                  'label' => 'Granted Note',
                                  'persistent_id' => SecureRandom.hex
                                })),
      :last_modified_by => row[:last_modified_by],
      :create_time => row[:create_time],
      :system_mtime => row[:system_mtime],
      :user_mtime => row[:user_mtime]
    )
  end
end


def migrate_license_terms
  self[:rights_statement]
    .filter(Sequel.~(:license_identifier_terms => nil))
    .update(:license_terms => :license_identifier_terms)
end


def migrate_agent_rights_statements
  # Migrate any agent rights statements to a new note type 'Rights Statement'
  # known by the schema note_agent_rights_statement
  #
  # Required fields:
  #   Rights Type; Materials; Type Note; Permissions; Restrictions; State Date;
  #   End Date; Granted Note; IP Status; IP Expiration Date; Jurisdiction;
  #   License Identifier Terms; Statute Citation
  #
  [:agent_person_id,
   :agent_family_id,
   :agent_corporate_entity_id,
   :agent_software_id].each do |agent_fk|
    self[:rights_statement]
      .left_outer_join(:enumeration_value,
                    {
                      :rights_type_enum__id => :rights_statement__rights_type_id,
                    },
                    {
                      :table_alias => :rights_type_enum
                    })
      .left_outer_join(:enumeration_value,
                       {
                         :jurisdiction_enum__id => :rights_statement__jurisdiction_id,
                       },
                       {
                         :table_alias => :jurisdiction_enum
                       })
      .left_outer_join(:enumeration_value,
                       {
                         :ip_status_enum__id => :rights_statement__ip_status_id,
                       },
                       {
                         :table_alias => :ip_status_enum
                       })
      .filter(Sequel.~(Sequel.qualify(:rights_statement, agent_fk) => nil))
      .select(Sequel.as(:rights_type_enum__value, :rights_type),
              Sequel.as(:rights_statement__materials, :materials),
              Sequel.as(:rights_statement__type_note, :type_note),
              Sequel.as(:rights_statement__permissions, :permissions),
              Sequel.as(:rights_statement__restrictions, :restrictions),
              Sequel.as(:rights_statement__restriction_start_date, :start_date),
              Sequel.as(:rights_statement__restriction_end_date, :end_date),
              Sequel.as(:rights_statement__granted_note, :granted_note),
              Sequel.as(:ip_status_enum__value, :ip_status),
              Sequel.as(:rights_statement__ip_expiration_date, :ip_expiration_date),
              Sequel.as(:jurisdiction_enum__value, :jurisdiction),
              Sequel.as(:rights_statement__license_identifier_terms, :license_identifier_terms),
              Sequel.as(:rights_statement__statute_citation, :statute_citation),
              Sequel.as(Sequel.qualify(:rights_statement, agent_fk), agent_fk),
              Sequel.as(:rights_statement__last_modified_by, :last_modified_by),
              Sequel.as(:rights_statement__create_time, :create_time),
              Sequel.as(:rights_statement__system_mtime, :system_mtime),
              Sequel.as(:rights_statement__user_mtime, :user_mtime))
      .each do |row|

      note_content = ""
      note_content += "Rights Type: #{row[:rights_type]}"
      note_content += "\nMaterials: #{row[:materials]}" if row[:materials]
      note_content += "\nType Note: #{row[:type_note]}" if row[:type_note]
      note_content += "\nPermissions: #{row[:permissions]}" if row[:permissions]
      note_content += "\nRestrictions: #{row[:restrictions]}" if row[:restrictions]
      note_content += "\nStart Date: #{row[:start_date]}" if row[:start_date]
      note_content += "\nEnd Date: #{row[:end_date]}" if row[:end_date]
      note_content += "\nGranted Note: #{row[:granted_note]}" if row[:granted_note]
      note_content += "\nIP Status: #{row[:ip_status]}" if row[:ip_status]
      note_content += "\nIP Expiration Date: #{row[:ip_expiration_date]}" if row[:ip_expiration_date]
      note_content += "\nJurisdiction: #{row[:jurisdiction]}" if row[:jurisdiction]
      note_content += "\nLicense Identifier Terms: #{row[:license_identifier_terms]}" if row[:license_identifier_terms]
      note_content += "\nStatute Citation #{row[:statute_citation]}" if row[:statute_citation]

      self[:note].insert(
        agent_fk => row[agent_fk],
        :publish => 0,
        :notes_json_schema_version => 1,
        :notes => blobify(self, JSON.generate({
                                    'jsonmodel_type' => 'note_agent_rights_statement',
                                    'content' => [note_content],
                                    'persistent_id' => SecureRandom.hex
                                  })),
        :last_modified_by => row[:last_modified_by],
        :create_time => row[:create_time],
        :system_mtime => row[:system_mtime],
        :user_mtime => row[:user_mtime]
      )
    end

    # link any agent rights statement external documents to the agent instead
    self[:external_document]
      .join(:rights_statement, :rights_statement__id => :external_document__rights_statement_id)
      .filter(Sequel.~(Sequel.qualify(:rights_statement, agent_fk) => nil))
      .select(Sequel.as(:external_document__id, :external_document_id),
              Sequel.as(Sequel.qualify(:rights_statement, agent_fk), agent_fk))
      .each do |row|

      self[:external_document]
        .filter(:id => row[:external_document_id])
        .update(:rights_statement_id => nil,
                :identifier_type_id => nil,
                agent_fk => row[agent_fk])
    end
  end
end


def drop_old_rights_statement_columns
  alter_table(:rights_statement) do
    # drop fks
    drop_foreign_key [:ip_status_id] #, :name => :rights_statement_ibfk_2

    # drop columns
    drop_column(:active)
    drop_column(:ip_status_id)
    drop_column(:restriction_start_date)
    drop_column(:restriction_end_date)
    drop_column(:materials)
    drop_column(:ip_expiration_date)
    drop_column(:type_note)
    drop_column(:permissions)
    drop_column(:restrictions)
    drop_column(:granted_note)
    drop_column(:license_identifier_terms)
  end
end


def drop_agent_rights_statements
  self[:rights_statement]
    .filter(Sequel.|(
      Sequel.~(:agent_person_id => nil),
      Sequel.~(:agent_family_id => nil),
      Sequel.~(:agent_corporate_entity_id => nil),
      Sequel.~(:agent_software_id => nil)
    ))
    .delete

  alter_table(:rights_statement) do
    drop_foreign_key [:agent_person_id]
    drop_foreign_key [:agent_family_id]
    drop_foreign_key [:agent_corporate_entity_id]
    drop_foreign_key [:agent_software_id]

    drop_column(:agent_person_id)
    drop_column(:agent_family_id)
    drop_column(:agent_corporate_entity_id)
    drop_column(:agent_software_id)
  end
end


def coerce_date(date)
  if date =~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/
    date # Date.strptime(date, '%Y-%m-%d')
  elsif date =~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]/
    "#{date}-01" # Date.strptime("#{date}-01", '%Y-%m-%d')
  elsif date =~ /[0-9][0-9][0-9][0-9]/
    "#{date}-01-01" # Date.strptime("#{date}-01-01", '%Y-%m-%d')
  else
    raise "Not a date: #{date}"
  end
end


def coerce_timestamp(timestamp)
  timestamp.strftime('%Y-%m-%d')
end

Sequel.migration do

  up do
    # backup! just. in. case.
    backup_rights_statement_table

    # create new tables/relationships
    create_rights_statement_act
    link_acts_to_notes
    link_rights_statements_to_agents
    link_rights_statements_to_notes
    add_identifier_type_to_external_documents
    add_new_rights_statement_columns

    # drop agent rights statements first...
    migrate_agent_rights_statements
    drop_agent_rights_statements

    # migrate all the other rights statements now...
    migrate_rights_statement_start_date
    migrate_rights_statement_types
    reorder_rights_statement_types
    migrate_ip_status
    migrate_license_terms
    migrate_ip_expiration_date
    migrate_other_rights_basis
    migrate_materials_to_note
    migrate_type_to_note
    migrate_permissions_to_note
    migrate_restrictions_to_note
    migrate_granted_note_to_note

    # and drop what we don't need anymore...
    drop_old_rights_statement_columns
  end

  down do
    # To recover pre-088 rights statements, refer to the copy of the
    # rights_statement table named `rights_statement_pre_088`
  end

end
