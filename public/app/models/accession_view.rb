# Restrict an JSONModel(:accession) to a subset
class AccessionView < ArchivalRecordView

  def published_related_resources
    Array(@record['related_resources']).find_all {|doc| doc['_resolved']['publish'] === true}
  end

end
