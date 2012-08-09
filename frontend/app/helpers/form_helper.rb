require 'markaby'

module FormHelper
   def self.included(base)
    ActionView::Helpers::FormBuilder.instance_eval do
      include FormBuilderMethods
    end
   end

   module FormBuilderMethods   
      def label_field_pair(method, field_html, extra_args  = {})
         extra_args.reject! {|k,v| v.blank?}
         
         control_group_classes = "control-group"
         control_group_classes << " warning" if @object._exceptions.has_key?(:warnings) && @object._exceptions[:warnings].has_key?(method.to_s)
         control_group_classes << " error" if @object._exceptions.has_key?(:errors) && @object._exceptions[:errors].has_key?(method.to_s)
                  
         control_classes = "controls"
         control_classes << " #{extra_args[:control_class]}" if extra_args.has_key? :control_class
         
         label_html = @template.label @object_name, method, I18n.t("#{@object_name}.#{method}"), :class=> "control-label"
         
         mab = Markaby::Builder.new
         mab.div :class=>control_group_classes do           
            self << label_html
            self.div :class=> control_classes do
               self << field_html
            end
         end         
         mab.to_s.html_safe
      end
   end
end