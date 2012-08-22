require 'markaby'

module FormHelper
   def self.included(base)
    ActionView::Helpers::FormBuilder.instance_eval do
      include FormBuilderMethods
    end
   end

   module FormBuilderMethods   
      def label_field_pair(method, field_html=nil, extra_args  = {})
         extra_args.reject! {|k,v| v.blank?}
         
         control_group_classes = "control-group"
         control_group_classes << " warning" if @object._exceptions.has_key?(:warnings) && @object._exceptions[:warnings].has_key?(method.to_s)
         control_group_classes << " error" if @object._exceptions.has_key?(:errors) && @object._exceptions[:errors].has_key?(method.to_s)
                  
         control_classes = "controls"
         control_classes << " #{extra_args[:control_class]}" if extra_args.has_key? :control_class
         
         label_html = @template.label @object_name, method, I18n.t("#{@object_name}.#{method}"), :class=> "control-label"
         
         field_html = jsonmodel_field(method) if field_html.blank?
         
         mab = Markaby::Builder.new
         mab.div :class=>control_group_classes do           
            self << label_html
            self.div :class=> control_classes do
               self << field_html
            end
         end         
         mab.to_s.html_safe
      end
      
      def label_and_fourpartid(method, extra_args  = {})
         extra_args[:control_class] = "identifier-fields"
         field_html =  @template.text_field(@object_name, :id_0, :class=> "id_0", :size=>10)
         field_html << @template.text_field(@object_name, :id_1, :class=> "id_1", :size=>10, :disabled=>@object[:id_0].blank? && @object[:id_1].blank?)
         field_html << @template.text_field(@object_name, :id_2, :class=> "id_2", :size=>10, :disabled=>@object[:id_1].blank? && @object[:id_2].blank?)
         field_html << @template.text_field(@object_name, :id_3, :class=> "id_3", :size=>10, :disabled=>@object[:id_2].blank? && @object[:id_3].blank?)
         label_field_pair(method, field_html, extra_args)
      end
      
      def jsonmodel_field(method)
         schema = @object.class.schema
         if not schema["properties"].has_key?(method.to_s)
            return "PROBLEM: #{object_name} does not define #{method} in it's schema"
         end
         attr_definition = schema["properties"][method.to_s]
         if attr_definition.has_key?("enum")
            @template.select(@object_name, method, attr_definition["enum"])
         else
            @template.text_field(@object_name, method, "data-original_value"=>@object[method])
         end
      end
   end
end
