# Modified to return descriptions in OAI_DC format so our responses validate.
module OAI::Provider::Response

  class ListSets < Base
    def to_xml
      raise OAI::SetException.new unless provider.model.sets

      response do |r|
        r.ListSets do
          provider.model.sets.each do |set|
            r.set do
              r.setSpec set.spec
              r.setName set.name
              if set.respond_to?(:description) && set.description
                r << set.description
              end
            end
          end
        end
      end
    end
  end

end
