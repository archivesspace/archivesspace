class UnprocessedAccessionsReport < AbstractReport

  register_report

  def headers
    ['id', 'identifier', 'title', "processing_priority", "processing_status", "processors"]
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")}
    }
  end

  def query
    dataset = db[:accession].
      left_outer_join(:collection_management, :accession_id => :id).
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
      left_outer_join(:enumeration_value,
           {
            Sequel.qualify(:enumvals_processing_status, :enumeration_id) =>  Sequel.qualify(:enum_processing_status, :id),
            Sequel.qualify(:collection_management, :processing_status_id) => Sequel.qualify(:enumvals_processing_status, :id),
           },
           {
             :table_alias => :enumvals_processing_status
           }).
      left_outer_join(:enumeration_value,
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

    dataset = dataset.where(Sequel.qualify(:accession, :repo_id) => @repo_id) if @repo_id

    dataset.from_self(:alias => :all_results).
      filter(Sequel.|(
               Sequel.~(Sequel.qualify(:all_results, :processing_status) => 'completed'),
               {
                 Sequel.qualify(:all_results, :processing_status) => nil
               }
             )).
      order_by(Sequel.asc(:processing_priority), Sequel.asc(:processing_status), Sequel.asc(:title))
  end

end
