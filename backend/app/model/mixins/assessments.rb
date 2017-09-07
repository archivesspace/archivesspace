module Assessments
  module LinkedRecord
    def self.included(base)
      base.define_relationship(:name => :assessment,
                               :contains_references_to_types => proc{[Assessment]})
    end

    def delete
      # only allow delete of the record if not linked to any assessments
      object_graph = self.object_graph

      assessment_rlshp = self.class.find_relationship(:assessment)

      if object_graph.models.any? {|model| model.is_relationship? && model == assessment_rlshp }
        raise ConflictException.new("linked_to_assessment")
      end

      super
    end
  end


  module LinkedAgent
    def self.included(base)
      base.define_relationship(:name => :surveyed_by,
                               :contains_references_to_types => proc{[Assessment]})
      base.define_relationship(:name => :assessment_reviewer,
                               :contains_references_to_types => proc{[Assessment]})
    end

    def delete
      # only allow delete of the agent if not linked to any assessments
      object_graph = self.object_graph

      assessment_rlshps = [self.class.find_relationship(:surveyed_by),
                           self.class.find_relationship(:assessment_reviewer)]

      if object_graph.models.any? {|model| model.is_relationship? && assessment_rlshps.include?(model) }
        raise ConflictException.new("linked_to_assessment")
      end

      super
    end
  end
end
