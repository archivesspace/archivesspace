require_relative 'jasper_report'

class LocationsReport < JasperReport

  register_report({
                    :uri_suffix => "locations",
                    :description => "Report on repository locations",
                  })

  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end

  def query
    results = nil 
    DB.open do |db|
      locations = db[:location].select(:building, :title, :floor, :room, :area, :barcode, :classification, :id ).all
      
      resources = db[:location].
        join(:housed_at_rlshp, :location_id => :location__id).
        join(:container, :id => :housed_at_rlshp__container_id).
        join(:instance,{  :id => :container__instance_id} , :table_alias => :instance ).
        join(:enumeration_value, :id => :instance__instance_type_id).
        join(:resource, { :id => :instance__resource_id }, :table_alias => :resource ).
        join(:repository, :id => :resource__repo_id).
        where(Sequel.qualify(:repository, :id) => @repo_id).
        select(:resource__id, :resource__title, Sequel.as( :location__id, :location_id), Sequel.as( :enumeration_value__value, :instance_type)).  
        all
       
      accessions = db[:location].
        join(:housed_at_rlshp, :location_id => :location__id).
        join(:container, :id => :housed_at_rlshp__container_id).
        join(:instance, :id => :container__instance_id).
        join(:accession, :id => :instance__accession_id).
        join(:repository, :id => :accession__repo_id).
        where(Sequel.qualify(:repository, :id) => @repo_id).
        select(:accession__id, :accession__title, :accession__identifier,  Sequel.as( :location__id, :location_id)).
        all
      
      results = { :locations => locations, :resources => resources, :accessions => accessions }
    end 
    results
  end

end
