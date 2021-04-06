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
      # ANW-617: most of the sluggable classes run their slug code via calls to auto_generate on the slug property.

      # The code in this hook ensures that:
      # - all slugs are cleaned.
      # - if we end up autogenning an empty slug, we turn is_slug_auto off for that entity
      # - the special cases for Agents are handled
      # - ignores setting for use_human_readable_urls for repositories which have
      #   slugs generated regardless of the setting for use_human_readable_urls

      if AppConfig[:use_human_readable_urls]
        # Special case for generating slugs for Agents by name
        # This special case is necessary because the NameAgent classes don't have a slug field themselves, but they have the data we need to generate the slug.
        if SlugHelpers.is_agent_name_type?(self.class) &&
           SlugHelpers.slug_data_updated?(self) &&
           SlugHelpers.is_slug_auto_enabled?(self) &&
           !AppConfig[:auto_generate_slugs_with_id]

          SlugHelpers.generate_slug_for_agent_name!(self)
        end

        # For all types
        # If the slug has changed manually, then make sure it's cleaned and deduped.
        if self[:slug] &&
           (self.column_changed?(:slug) || !self.exists?) &&
           !SlugHelpers::is_slug_auto_enabled?(self)

          cleaned_slug = SlugHelpers.clean_slug(self[:slug])
          self[:slug] = SlugHelpers.run_dedupe_slug(cleaned_slug)
        end

        # For all non-agent types except repositories that have a slug field
        # If the slug is empty at this point and is_slug_auto is enabled,
        # then we didn't have enough data to generate one, so we'll turn
        # is_slug_auto off
        if SlugHelpers.base_sluggable_class?(self.class) &&
           (self[:slug].nil? || self[:slug].empty?) &&
           !SlugHelpers.is_agent_type?(self.class) &&
           SlugHelpers.is_slug_auto_enabled?(self)

          self[:is_slug_auto] = 0
        end

        # Repositories must always have a slug so, if repository and
        # there is no slug, auto generate a repo slug based on repo_code.
        if self.class == Repository &&
           (self[:slug].nil? || self[:slug].empty?)

          cleaned_slug = SlugHelpers.clean_slug(self[:repo_code])
          self[:slug] = SlugHelpers.run_dedupe_slug(cleaned_slug)
          self[:is_slug_auto] = 1
        end

        # This block is the same as above, but a special case for Agent classes when generating by ID only.
        # We can't autogen an empty slug for an agent based on name, because the primary name field is required.
        # Running this code when generating by name breaks things because autogen is flipped off for the agent and then the name record update does't run like it should
        if SlugHelpers.is_agent_type?(self.class) &&
          AppConfig[:auto_generate_slugs_with_id] == true &&
          (self[:slug].nil? || self[:slug].empty?) &&
          SlugHelpers.is_slug_auto_enabled?(self)

          self[:is_slug_auto] = 0
        end
      elsif self.class == Repository
        if (!self.exists? && (self[:slug].nil? || self[:slug].empty?))
          cleaned_slug = SlugHelpers.clean_slug(self[:repo_code])
          self[:slug] = SlugHelpers.run_dedupe_slug(cleaned_slug)
          self[:is_slug_auto] = 1
        elsif !SlugHelpers::is_slug_auto_enabled?(self) &&
              !self[:slug].nil? && !self[:slug].empty? &&
              self.column_changed?(:slug)

          cleaned_slug = SlugHelpers.clean_slug(self[:slug])
          self[:slug] = SlugHelpers.run_dedupe_slug(cleaned_slug)
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
