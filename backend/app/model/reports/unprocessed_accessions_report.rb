class UnprocessedAccessionsReport < AbstractReport
  register_report({
                    :uri => "/reports/unprocessed_accessions",
                    :description => "Report on all unprocessed accessions",
                  })

  def initialize(params)
    super
  end

  def headers
    ['id', 'identifier', 'title', "processing_status", "processors"]
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
      'processing_status' => proc {|record| record[:value]}
    }
  end

  def query(db)
    db[:accession].
      join(:collection_management, :accession_id => :id).
      join(:enumeration, :name => 'collection_management_processing_status').
      join(:enumeration_value, Sequel.qualify(:enumeration_value, :enumeration_id) =>  Sequel.qualify(:enumeration, :id), Sequel.qualify(:collection_management, :processing_status_id) => Sequel.qualify(:enumeration_value, :id))
  end

end