module ConverterExtraContainerValues


  def self.included(base)
    base.extend(ClassMethods)

    base.class_eval do
      self.singleton_class.send(:alias_method, :configure_pre_manage_containers, :configure)
      def self.configure
        configure_pre_manage_containers

        managed_containers_configure
      end
    end
  end


  module ClassMethods
    def managed_containers_configure
      with 'container' do
        @containers ||= {}

        # we've found that the container has a parent att and the parent is in
        # our queue
        if att("parent") && @containers[att('parent')]
          cont = @containers[att('parent')]

        else
          instance_label = att("label") ? att("label").downcase : 'mixed_materials'

          if instance_label =~ /(.*)\s\[([0-9]+)\]$/
            instance_label = $1
            barcode = $2
          end

          make :instance, {
            :instance_type => instance_label
          } do |instance|
            set ancestor(:resource, :archival_object), :instances, instance
          end

          inst = context_obj

          make :container do |cont|
            set inst, :container, cont
          end

          cont =  inst.container
          cont['barcode_1'] = barcode if barcode
          cont['container_profile_key'] = att("altrender")
        end

        # now we fill it in
        (1..3).to_a.each do |i|
          next unless cont["type_#{i}"].nil?
          cont["type_#{i}"] = att('type')
          cont["indicator_#{i}"] = format_content( inner_xml )
          break
        end
        #store it here incase we find it has a parent
        @containers[att("id")] = cont

      end
    end
  end

end