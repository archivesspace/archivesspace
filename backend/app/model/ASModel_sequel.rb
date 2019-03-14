module ASModel

  # Hooks for firing behaviour on Sequel::Model events
  module SequelHooks

    def self.included(base)
      base.extend(BlobHack)
    end


    # We can save quite a lot of database chatter by only refreshing our
    # top-level records upon save.  Pure-nested records don't need refreshing,
    # so skip them.
    def _save_refresh
      if self.class.is_a?(ASModel) && self.class.top_level?
        _refresh(this.opts[:server] ? this : this.server(:default))
      end
    end

    def before_create
      if RequestContext.get(:current_username)
        self.created_by = self.last_modified_by = RequestContext.get(:current_username)
      end
      self.create_time = Time.now
      self.system_mtime = self.user_mtime = Time.now
      super
    end

    def before_save
      if AppConfig[:use_human_readable_URLs]
        if SlugHelpers.sluggable_class?(self.class) &&
           self.respond_to?(:column_changed?) && 
           SlugHelpers.slug_data_updated?(self)

          if SlugHelpers.is_slug_auto_enabled?(self)
            auto_gen_slug!
          elsif self[:slug]
            self[:slug] = SlugHelpers.clean_slug(self[:slug], self.class)
          end
        end
      end
    end


    def before_update
      if RequestContext.get(:current_username)
        self.last_modified_by = RequestContext.get(:current_username)
      end
      self.system_mtime = Time.now
      super
    end


    def around_save
      values_to_reapply = {}

      self.class.blob_columns_to_fix.each do |column|
        if self[column]
          values_to_reapply[column] = self[column]
          self[column] = "around_save_placeholder"
        end
      end

      ret = super

      if !values_to_reapply.empty?
        ps = self.class.dataset.where(:id => self.id).prepare(:update, :update_blobs,
                                                             Hash[values_to_reapply.keys.map {|c| [c, :"$#{c}"]}])

        ps.call(Hash[values_to_reapply.map {|k, v| [k, DB.blobify(v)]}])

        self.refresh
      end

      ret
    end

    private

      def auto_gen_slug!
        if AppConfig[:auto_generate_slugs_with_id]
          SlugHelpers.generate_slug_by_id!(self)
        else
          SlugHelpers.generate_slug_by_name!(self)
        end
      end

      module BlobHack
        def self.extended(base)
          blob_columns = base.db_schema.select {|column, defn| defn[:type] == :blob}.keys

          base.instance_eval do
            @blob_columns_to_fix = (!blob_columns.empty? && DB.needs_blob_hack?) ? Array(blob_columns) : []
          end
        end

        def blob_columns_to_fix
          @blob_columns_to_fix
        end
      end


  end
end
