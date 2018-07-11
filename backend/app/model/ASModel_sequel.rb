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

    # Slugs:
    # autogenerate a slug based on name/title if flag is set.
    # make sure slug has no invalid chars and is valid length
    # make sure slug is de-duped.
    def before_save
      if self[:is_slug_auto] == 1
        if AppConfig[:auto_generate_slugs_with_id]
          auto_gen_slug_on_id!
        else
          auto_gen_slug_on_name!
        end

      end

      if self[:slug]
        # replace spaces with underscores
        self[:slug] = self[:slug].gsub(" ", "_")

        # remove URL-reserved chars
        self[:slug] = self[:slug].gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!.]/, "")

        # enforce length limit of 50 chars
        self[:slug] = self[:slug].slice(0, 50)

        # search for dupes
        if SlugHelpers.slug_in_use?(self[:slug])
          self[:slug] = SlugHelpers.dedupe_slug(self[:slug])
        end
      end
    end

    # auto generate a slug for this instance based on name
    def auto_gen_slug_on_name!
      if !self[:title].nil? && !self[:title].empty?
        self[:slug] = self[:title]

      elsif !self[:name].nil? && !self[:name].empty?
        self[:slug] = self[:name]

      else
        # if Agent, go look in the AgentContact table.
        if self.class == AgentCorporateEntity ||
           self.class == AgentPerson ||
           self.class == AgentFamily ||
           self.class == AgentSoftware

          self[:slug] = SlugHelpers.get_agent_name(self.id, self.class)

        # otherwise, make something up.
        else
          self[:slug] = SlugHelpers.random_name
        end
      end
    end

    # auto generate a slug for this instance based on id
    def auto_gen_slug_on_id!
      self[:slug] = SlugHelpers.random_name
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
