class ArchivalObjectChildren < JSONModel(:archival_object_children)

  attr_accessor :uri

  def self.uri_and_remaining_options_for(id = nil, opts = {})
    [URI("/repositories/#{opts[:repo_id]}/archival_objects/#{id}/children"), opts]
  end

  def self.uri_for(*args)
    nil
  end

end
