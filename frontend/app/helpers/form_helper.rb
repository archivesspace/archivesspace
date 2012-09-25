require 'markaby'


module ActionView
  module Helpers
    module TagHelper

      def tag(name, options = nil, open = false, escape = true)
        options["name"] = options["force_name"] if options["force_name"]
        options["id"] = options["force_id"] if options["force_id"]

        "<#{name}#{tag_options(options, escape) if options}#{open ? ">" : " />"}".html_safe
      end

    end
  end
end


module FormHelper
  def self.included(base)
    ActionView::Helpers::FormBuilder.instance_eval do
      include FormBuilderMethods
    end
  end


  module FormBuilderMethods


    def with_jsonmodel(name, obj, model, opts = {})

      if model.is_a? Symbol
        model = JSONModel(model)
      end

      @json_index ||= {}
      @json_index[model] ||= -1

      if obj.is_a? Hash
        obj = model.new(obj)
      end

      @json_index[model] += 1
      opts[:index] ||= @json_index[model].to_s

      @jsonmodel_object ||= []

      if name =~ /^(.*)\[\]$/
        @jsonmodel_object << [$1, obj, opts.merge(:is_array => true)]
      else
        @jsonmodel_object << [name, obj, opts]
      end

      result = yield

      @jsonmodel_object.pop

      result
    end


    def current_name(method, use_index = true)
      result = @object_name

      (@jsonmodel_object or []).each do |name, _, opts|
        result += "[#{name}]"

        if opts[:is_array]
          if use_index
            result += "[#{opts[:index]}]"
          else
            result += "[]"
          end
        end

      end

      result += "[#{method}]"

      result
    end


    def current_i18n(method)
      current_name(method, false)
    end


    def document_path(method)
      result = []

      (@jsonmodel_object or []).each do |name, _, opts|

        result << name

        if opts[:is_array]
          result << opts[:index]
        end

      end

      result << method

      result.join("/")
    end


    def current
      if @jsonmodel_object
        @jsonmodel_object.last[1]
      else
        @object
      end
    end


    def error_classes(method)
      classes = ""
      classes << " warning" if @object._exceptions.has_key?(:warnings) && @object._exceptions[:warnings].has_key?(document_path(method))
      classes << " error" if @object._exceptions.has_key?(:errors) && @object._exceptions[:errors].has_key?(document_path(method))
      classes
    end


    def label_with_field(method, field_html, extra_args  = {})
      extra_args.reject! {|k,v| v.blank?}

      control_group_classes = "control-group"
      control_group_classes << " " + error_classes(method)

      control_classes = "controls"
      control_classes << " #{extra_args[:control_class]}" if extra_args.has_key? :control_class

      label_html = jsonmodel_label(method, extra_args[:label_opts]||{})

      mab = Markaby::Builder.new
      mab.div :class => control_group_classes do
        self << label_html
        self.div :class=> control_classes do
          self << field_html
        end
      end
      mab.to_s.html_safe
    end


    def label_and_field(method, extra_args = {})
      label_with_field(method, jsonmodel_field(method, extra_args[:field_opts]||{}), extra_args)
    end


    def label_and_textarea(method, extra_args = {})
      label_with_field method, jsonmodel_text_area(method, :rows => 3), extra_args
    end


    def label_and_fourpartid(method, extra_args  = {})
      extra_args[:control_class] = "identifier-fields"
      field_html =  jsonmodel_text_field(:id_0, :class=> "id_0", :size => 10)
      field_html << jsonmodel_text_field(:id_1, :class=> "id_1", :size => 10, :disabled => current[:id_0].blank? && current[:id_1].blank?)
      field_html << jsonmodel_text_field(:id_2, :class=> "id_2", :size => 10, :disabled => current[:id_1].blank? && current[:id_2].blank?)
      field_html << jsonmodel_text_field(:id_3, :class=> "id_3", :size => 10, :disabled => current[:id_2].blank? && current[:id_3].blank?)
      label_with_field(method, field_html, extra_args)
    end


    def jsonmodel_label(method, opts = {})
      field_id = opts[:force_id] || current_name(method, true)
      "<label for=\"#{field_id}\" class=\"control-label\">#{I18n.t(current_i18n(method))}</label>".html_safe
    end


    def jsonmodel_field(method, opts = {})
      schema = current.class.schema

      if not schema["properties"].has_key?(method.to_s)
        return "PROBLEM: #{object_name} does not define #{method} in its schema"
      end
      attr_definition = schema["properties"][method.to_s]

      if attr_definition.has_key?("enum")
        options_array = attr_definition["enum"].collect {|option| [I18n.t(current_i18n("#{method}_#{option}")), option]}

        if not attr_definition["required"]
          options_array = [""].concat(options_array)
        end

        @template.select(current, method, 
                         options_array, 
                         {
                           :selected => current[method] || options_array.first
                         },
                         {
                           "data-original_value" => current[method],
                           :name => current_name(method),
                           :id => current_name(method, true)
                         }.merge(opts))
      else
        jsonmodel_text_field(method, opts)
      end
    end


    def jsonmodel_text_field(method, opts = {})
      @template.text_field(@object_name, method, {
                             "data-original_value" => current[method],
                             :object => current,
                             :force_name => current_name(method),
                             :force_id => current_name(method, true)
                           }.merge(opts))
    end

    def jsonmodel_radio(method, value)
      @template.radio_button(@object_name, method, value, {
                             "data-original_value" => current[method],
                             :object => current,
                             :force_name => current_name(method),
                             :force_id => current_name(method, true)
                           })
    end

    def jsonmodel_text_area(method, opts)
      @template.text_area(@object_name, method, {
                             "data-original_value" => current[method],
                             :object => current,
                             :name => current_name(method),
                             :id => current_name(method, true)
                           }.merge(opts))
    end

  end
end
