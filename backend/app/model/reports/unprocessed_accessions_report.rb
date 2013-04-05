class UnprocessedAccessionsReport < AbstractReport
  register_report({
                    :uri => "/reports/unprocessed_accessions",
                    :description => "Report on all unprocessed accessions",
                  })

  def initialize(params)
    super
  end

  def headers
    ['id', 'identifier', 'title', "processing_priority", "processing_status", "processors"]
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")}
    }
  end

  def query(db)
    db[:accession].
      join(:collection_management, :accession_id => :id).
      join(:enumeration,
           {
              :name => 'collection_management_processing_status'
           },
           {
             :table_alias => :enum_processing_status
           }).
      join(:enumeration,
           {
             :name => 'collection_management_processing_priority'
           },
           {
             :table_alias => :enum_processing_priority
           }).
      join(:enumeration_value,
           {
             Sequel.qualify(:enumvals_processing_status, :enumeration_id) =>  Sequel.qualify(:enum_processing_status, :id),
             Sequel.qualify(:collection_management, :processing_status_id) => Sequel.qualify(:enumvals_processing_status, :id),
             Sequel.qualify(:enumvals_processing_status, :value) => ['new', 'in_progress']
           },
           {
             :table_alias => :enumvals_processing_status
           }).
      join(:enumeration_value,
           {
            Sequel.qualify(:enumvals_processing_priority, :enumeration_id) =>  Sequel.qualify(:enum_processing_priority, :id),
            Sequel.qualify(:collection_management, :processing_priority_id) => Sequel.qualify(:enumvals_processing_priority, :id),
           },
           {
             :table_alias => :enumvals_processing_priority
           }).
      select(
        Sequel.qualify(:accession, :id),
        Sequel.qualify(:accession, :identifier),
        Sequel.qualify(:accession, :title),
        Sequel.qualify(:collection_management, :processors),
        Sequel.qualify(:enumvals_processing_status, :value).as(:processing_status),
        Sequel.qualify(:enumvals_processing_priority, :value).as(:processing_priority)
      )
  end

end