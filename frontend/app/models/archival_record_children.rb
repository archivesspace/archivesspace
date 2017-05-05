require_relative "mixins/record_children"

class ArchivalRecordChildren < JSONModel(:archival_record_children)

  include RecordChildren


  attr_accessor :uri

  def self.uri_for(*args)
    nil
  end

end
