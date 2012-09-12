require 'markaby'

class JsonmodelFormBuilder < ActionView::Helpers::FormBuilder

#  def initialize(object_name, object, template, options, proc)
#    super
#    @object_name = @object_name.sub!(/\[\d+?\]/,"[]")
#  end
  
  def jsonmodel_label_and_field(method)
    control_group_classes = "control-group"
    control_group_classes << " warning" if object._exceptions.has_key?(:warnings) && @object._exceptions[:warnings].has_key?(method.to_s)
    control_group_classes << " error" if object._exceptions.has_key?(:errors) && object._exceptions[:errors].has_key?(method.to_s)

    control_classes = "controls"
    #control_classes << " #{extra_args[:control_class]}" if extra_args.has_key? :control_class

    label_html = "<div class='control-label'><label for='#{id_for(method)}'>#{I18n.t(i18n_key_for(method))}</label></div>"
    field_html = jsonmodel_field(method)

    mab = Markaby::Builder.new
    mab.div :class => control_group_classes do
      self << label_html
      self.div :class=> control_classes do
        self << field_html
      end
    end
    mab.to_s.html_safe
  end


  def jsonmodel_field(method)
    schema = object.class.schema

    if not schema["properties"].has_key?(method.to_s)
      return "PROBLEM: #{object_name} does not define #{method} in it's schema"
    end

    attr_definition = schema["properties"][method.to_s]
    if attr_definition.has_key?("enum")
      raise Exception.new
    else
      "<input type='text' id='#{id_for(method)}' name='#{name_for(method)}' value='#{value_for(method)}' />"
    end
  end
  
  private 
    def i18n_key_for(method)
      prefix = @object_name.clone
      prefix.gsub!(Regexp.new(Regexp.escape(@options[:child_index])),"") if @options.has_key?(:child_index)
      prefix.gsub!(/\[\]/,"")
      prefix.gsub!(/\[\d+\]/,"")
      prefix.gsub!(/\[(.*?)\]/,'.\1')
      prefix.gsub!(/_attributes/,'')
      "#{prefix}.#{method}"
    end

    def id_for(method)
      prefix = @object_name.clone
      prefix.gsub!(/[\[\]]/,"_")
      "#{prefix}_#{method}"
    end

    def name_for(method)
      prefix = @object_name.clone
      prefix.gsub!(Regexp.new(Regexp.escape(@options[:child_index])),"") if @options.has_key?(:child_index)
      prefix.gsub!(/\[\d+\]/,"[]")
      "#{prefix}[#{method}]"
    end

    def value_for(method)
      v = @object[method]
      return "" if v.blank?
      v
    end


end