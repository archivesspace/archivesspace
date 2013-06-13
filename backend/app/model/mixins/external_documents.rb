module ExternalDocuments

  def publish!
    # publish all external documents
    self.external_document.each do |exdoc|
      exdoc.publish!
    end

    super
  end

  def self.included(base)
    base.many_to_many(:external_document,
                      :before_add => proc { |obj, item_to_add|
                        if obj.external_document.any?{|doc| doc.location == item_to_add.location}
                          raise Sequel::ValidationFailed.new("Duplicate entry for location: #{item_to_add.location}")
                        end

                        true
                      },
                      :join_table => "#{base.table_name}_external_document".intern,
                      :order => "#{base.table_name}_external_document__id".intern)

    base.def_nested_record(:the_property => :external_documents,
                           :contains_records_of_type => :external_document,
                           :corresponding_to_association  => :external_document,
                           :always_resolve => true)
  end

end
