# Restrict an JSONModel(:accession) to a subset
class ResourceView < ArchivalRecordView

  def published_related_accessions
    Array(@record['related_accessions']).find_all {|doc| doc['_resolved']['publish'] === true}
  end

end
