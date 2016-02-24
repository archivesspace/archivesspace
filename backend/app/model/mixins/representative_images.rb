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
      file_versions = json['instances'].select{|i| i['instance_type'] == 'digital_object'}.map {|inst| {:is_representative => inst['is_representative'], :obj => DigitalObject.to_jsonmodel(JSONModel(:digital_object).id_for(inst['digital_object']['ref'], json['repo_id'])) }}.select {|hash| hash[:obj]['publish'] }.map {|hash| hash[:obj]['file_versions'].map {|fv| fv.merge({'has_representative_parent' => hash[:is_representative]}) }}.flatten.select{|fv| fv['use_statement'] == 'image-service' && fv['publish']}.sort_by {|fv| fv['is_representative'] ? 0 : 1}.sort_by {|fv| fv['has_representative_parent'] ? 0 : 1}

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
