require 'csv'
module CsvTemplateGenerator
  class << self
    def q(*args)
      Sequel.qualify(*args)
    end

    def csv_for_top_container_generation(resource_id)
      dataset = DB.open do |ds|
        ds[:resource].
          inner_join(:archival_object, :root_record_id => :id).where(q(:resource, :id) => 8443).
          where(q(:resource, :id)  => resource_id).
          select(
            q(:archival_object, :id).as(:archival_object_id),
            q(:archival_object, :ref_id),
            q(:archival_object, :component_id),
            q(:resource, :title).as(:resource_title),
            q(:resource, :identifier)
          ).
          order(q(:archival_object, :id))
      end
    end
  end
end
