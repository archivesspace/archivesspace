require 'markaby'

module JsonmodelFormHelper

  def jsonmodel_label_and_field(object, method, name_prefix)
    control_group_classes = "control-group"
    control_group_classes << " warning" if object._exceptions.has_key?(:warnings) && @object._exceptions[:warnings].has_key?(method.to_s)
    control_group_classes << " error" if object._exceptions.has_key?(:errors) && object._exceptions[:errors].has_key?(method.to_s)

    control_classes = "controls"
    #control_classes << " #{extra_args[:control_class]}" if extra_args.has_key? :control_class

    #label_html = @template.label @object_name, method, I18n.t("#{i18n_key_for(@object_name)}.#{method}"), :class=> "control-label"
    label_html = label_tag "#{object.class.record_type}__#{method}", I18n.t("#{object.class.record_type}.#{method}"), :class=> "control-label"
    field_html = jsonmodel_field(object, method, "#{name_prefix}[#{method}]")

    mab = Markaby::Builder.new
    mab.div :class => control_group_classes do
      self << label_html
      self.div :class=> control_classes do
        self << field_html
      end
    end
    mab.to_s.html_safe
  end

  def jsonmodel_field(object, method, name)
    schema = object.class.schema
    if not schema["properties"].has_key?(method.to_s)
      return "PROBLEM: #{object_name} does not define #{method} in it's schema"
    end
    attr_definition = schema["properties"][method.to_s]
    if attr_definition.has_key?("enum")
      #@template.select(@object_name, method, attr_definition["enum"].collect {|option| [I18n.t("#{i18n_key_for(@object_name)}.#{option}"), option]})
    else
      #@template.text_field(@object_name, method, "data-original_value" => @object[method])
      text_field_tag "#{object.class.record_type}__#{method}", object[method], :name => name
    end
  end
end