require "erb"

if AppConfig.has_key?(:refid_rule) && AppConfig[:refid_rule]
  rule_template = ERB.new(AppConfig[:refid_rule])
  ArchivalObject.auto_generate(:property => :ref_id,
                               :generator => proc {|json|
                                 component = json
                                 resource = Resource.to_jsonmodel(JSONModel::JSONModel(:resource).id_for(json['resource']['ref']))
                                 resource['formatted_id'] = Identifiers.format(Identifiers.parse(resource.identifier))
                                 repository = Repository.to_jsonmodel(RequestContext.get(:repo_id))
                                 rule_template.result(binding())
                               },
                               :only_on_create => true)
end
