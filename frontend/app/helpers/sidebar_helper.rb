module SidebarHelper

  class SidebarGenerator

    def initialize(form, opts)
      ensure_properties(opts, [:record, :record_type])

      @form = form
      @opts = opts
    end

    def ensure_properties(opts, properties)
      properties.each do |p|
        raise "Missing required property: #{p}" if !opts[p]
      end
    end

    def render_for_view_and_edit(opts)
      ensure_properties(opts, [:subrecord_type, :property])

      @form.render(:partial => '/shared/sidebar_entry',
                   :locals => opts.merge(@opts))
    end

  end

end
