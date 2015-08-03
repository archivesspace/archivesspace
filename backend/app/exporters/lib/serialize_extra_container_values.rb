module SerializeExtraContainerValues


  class AltRenderCalculator

    def initialize
      @lookup_cache = Rufus::Lru::Hash.new(128)
    end

    def for_top_container_uri(uri)
      @lookup_cache.fetch(uri) {
        top_container_id = JSONModel::JSONModel(:top_container).id_for(uri)
        profile = TopContainer.any_repo[top_container_id].related_records(:top_container_profile)

        if profile
          @lookup_cache[uri] = (profile.url || profile.name)
        end
      }
    end

  end

  def self.included(base)
    base.class_eval do
      def serialize_container(inst, xml, fragments)
        manage_containers_serialize_container(inst, xml, fragments)
      end
    end
  end

  def altrender_calculator
    # Each EAD export gets its own serializer instance, so we can safely store
    # state between calls here.
    @altrender_calculator ||= AltRenderCalculator.new
  end

  def manage_containers_serialize_container(inst, xml, fragments)
    @parent_id = nil
    (1..3).each do |n|
      atts = {}
      next unless inst['container'].has_key?("type_#{n}") && inst['container'].has_key?("indicator_#{n}")
      @container_id = prefix_id(SecureRandom.hex)

      atts[:parent] = @parent_id unless @parent_id.nil?
      atts[:id] = @container_id
      @parent_id = @container_id

      atts[:type] = inst['container']["type_#{n}"]
      text = inst['container']["indicator_#{n}"]

      if n == 1 && inst['instance_type']
        atts[:label] = I18n.t("enumerations.instance_instance_type.#{inst['instance_type']}", :default => inst['instance_type'])
        if inst['container']['barcode_1']
          atts[:label] << " [#{inst['container']['barcode_1']}]"
        end

        if inst['sub_container'] && inst['sub_container']['top_container']
          if (altrender = altrender_calculator.for_top_container_uri(inst['sub_container']['top_container']['ref']))
            atts[:altrender] = altrender
          end
        end
      end

      xml.container(atts) {
        sanitize_mixed_content(text, xml, fragments)
      }
    end
  end

end
