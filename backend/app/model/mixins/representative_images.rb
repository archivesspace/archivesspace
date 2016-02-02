# Mixin for selecting a "representative image" from the instances
# of an instance-having record.
# Candidate instances must:
#  - have digital objects
#  - link to a file version with an 'image-service' designation
# See also: https://archivesspace.atlassian.net/browse/AR-1294


module RepresentativeImages

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def populate_representative_image(json)
      file_versions = json['instances'].select{|i| i['instance_type'] == 'digital_object'}.map {|inst| inst['digital_object']['ref'] }.map{|ref| JSONModel(:digital_object).id_for(ref, json['repo_id'])}.map {|id| DigitalObject.to_jsonmodel(id) }.map {|obj| obj['file_versions'] }.flatten.select{|fv| fv['use_statement'] == 'image-service' }

      if file_versions.length > 0
        json.representative_image = JSONModel(:file_version).from_hash(file_versions.first)
      end
    end

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        populate_representative_image(json)
      end

      jsons
    end
  end
end
