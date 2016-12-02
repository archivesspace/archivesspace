require_relative '../../lib/aspace_json_to_managed_container_mapper'
require_relative '../../lib/subcontainer_to_aspace_json_mapper'

module MapToAspaceContainer

  def self.included(base)
    base.extend(ClassMethods)
  end


  def self.mapper_to_aspace_json
    if AppConfig.has_key?(:map_to_aspace_container_class)
      @mapper_to_aspace_json ||= Kernel.const_get(AppConfig[:map_to_aspace_container_class].intern)
    else
      @mapper_to_aspace_json ||= SubContainerToAspaceJsonMapper
    end
  end


  def self.mapper_to_managed_container
    if AppConfig.has_key?(:map_to_managed_container_class)
      @mapper_to_managed_container ||= Kernel.const_get(AppConfig[:map_to_managed_container_class].intern)
    else
      @mapper_to_managed_container ||= AspaceJsonToManagedContainerMapper
    end
  end


  def update_from_json(json, extra_values = {}, apply_nested_records = true)
    self.class.map_aspace_json_to_managed_containers(json, new_record = false)

    super
  end



  module ClassMethods

    def create_from_json(json, extra_values = {})
      map_aspace_json_to_managed_containers(json, new_record = true)

      super
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |record_json, record_obj|
        non_do_json_instances = Array(record_json['instances']).select {|instance| instance['instance_type'] != 'digital_object'}
        non_do_obj_instances = record_obj.instance.select {|instance| instance.instance_type != 'digital_object'}

        non_do_json_instances.zip(non_do_obj_instances).each do |instance_json, instance_obj|
          instance_json['container'] = map_managed_container_to_aspace_json(instance_json, instance_obj)
        end
      end

      jsons
    end


    def map_managed_container_to_aspace_json(instance_json, instance_object)
      mapper = MapToAspaceContainer.mapper_to_aspace_json.new(instance_json, instance_object)
      mapper.to_hash
    end

    def map_aspace_json_to_managed_containers(aspace_instance, new_record = true)
      MapToAspaceContainer.mapper_to_managed_container.new(aspace_instance, new_record).call
    end

  end

end
