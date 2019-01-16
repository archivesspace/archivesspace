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
      if SlugHelpers.slug_data_updated?(self)
        if self[:is_slug_auto] == 1
          auto_gen_slug!
        end
  
        if self[:slug]
          self[:slug] = SlugHelpers.clean_slug(self[:slug], self.class)
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

    # ANW-617
    # These methods are copy-pasted from the Sequel Dirty plugin.

    # Unfortunately, simply enabling the plugin as per the Sequel docs breaks other code (saving agent relationships with a date), due to the after_save hook the plugin re-defines.

    # So, we introduce the code necessary to support the column_changed? method we need.

    # TODO: This code should be in it's own module. Tried doing that and including the new module in ASModel.rb:31-37, but the methods aren't being included in ASModel classes correctly when done that way.

    ##### BEGIN SEQUEL DIRTY PLUGIN PUBLIC METHODS

    # A hash of previous changes before the object was
    # saved, in the same format as #column_changes.
    # Note that this is not necessarily the same as the columns
    # that were used in the update statement.
    attr_reader :previous_changes

    # An array with the initial value and the current value
    # of the column, if the column has been changed.  If the
    # column has not been changed, returns nil.
    #
    #   column_change(:name) # => ['Initial', 'Current']
    def column_change(column)
      [initial_value(column), get_column_value(column)] if column_changed?(column)
    end

    # A hash with column symbol keys and pairs of initial and
    # current values for all changed columns.
    #
    #   column_changes # => {:name => ['Initial', 'Current']}
    def column_changes
      h = {}
      initial_values.each do |column, value|
        h[column] = [value, get_column_value(column)]
      end
      h
    end

    # Either true or false depending on whether the column has
    # changed.  Note that this is not exactly the same as checking if
    # the column is in changed_columns, if the column was not set
    # initially.
    #
    #   column_changed?(:name) # => true
    def column_changed?(column)
      initial_values.has_key?(column)
    end

    # Freeze internal data structures
    def freeze
      initial_values.freeze
      missing_initial_values.freeze
      @previous_changes.freeze if @previous_changes
      super
    end

    # The initial value of the given column.  If the column value has
    # not changed, this will be the same as the current value of the
    # column.
    #
    #   initial_value(:name) # => 'Initial'
    def initial_value(column)
      initial_values.fetch(column){get_column_value(column)}
    end

    # A hash with column symbol keys and initial values.
    #
    #   initial_values # {:name => 'Initial'}
    def initial_values
      @initial_values ||= {}
    end

    # Reset the column to its initial value.  If the column was not set
    # initial, removes it from the values.
    #
    #   reset_column(:name)
    #   name # => 'Initial'
    def reset_column(column)
      if initial_values.has_key?(column)
        set_column_value(:"#{column}=", initial_values[column])
      end
      if missing_initial_values.include?(column)
        values.delete(column)
      end
    end

    # Manually specify that a column will change.  This should only be used
    # if you plan to modify a column value in place, which is not recommended.
    #
    #   will_change_column(:name)
    #   name.gsub(/i/i, 'o')
    #   column_change(:name) # => ['Initial', 'onotoal']
    def will_change_column(column)
      changed_columns << column unless changed_columns.include?(column)
      check_missing_initial_value(column)

      value = if initial_values.has_key?(column)
        initial_values[column]
      else
        get_column_value(column)
      end

      initial_values[column] = if value && value != true && value.respond_to?(:clone)
        begin
          value.clone
        rescue TypeError
          value
        end
      else
        value
      end
    end

    ##### END SEQUEL DIRTY PLUGIN PUBLIC METHODS


    private 

      def auto_gen_slug!
        if AppConfig[:auto_generate_slugs_with_id]
          SlugHelpers.generate_slug_by_id!(self)
        else
          SlugHelpers.generate_slug_by_name!(self)
        end
      end

      ##### BEGIN SEQUEL DIRTY PLUGIN PRIVATE METHODS

      # Reset the initial values when setting values.
      def _refresh_set_values(hash)
        reset_initial_values
        super
      end

      # When changing the column value, save the initial column value.  If the column
      # value is changed back to the initial value, update changed columns to remove
      # the column.
      def change_column_value(column, value)
        if (iv = initial_values).has_key?(column)
          initial = iv[column]
          super
          if value == initial
            changed_columns.delete(column) unless missing_initial_values.include?(column)
            iv.delete(column)
          end
        else
          check_missing_initial_value(column)
          iv[column] = get_column_value(column)
          super
        end
      end

      # If the values hash does not contain the column, make sure missing_initial_values
      # does so that it doesn't get deleted from changed_columns if changed back,
      # and so that resetting the column value can be handled correctly.
      def check_missing_initial_value(column)
        unless values.has_key?(column) || (miv = missing_initial_values).include?(column)
          miv << column
        end
      end

      # Duplicate internal data structures
      def initialize_copy(other)
        super
        @initial_values = other.initial_values.dup
        @missing_initial_values = other.send(:missing_initial_values).dup
        @previous_changes = other.previous_changes.dup if other.previous_changes
        self
      end

      # Reset the initial values when initializing.
      def initialize_set(h)
        super
        reset_initial_values
      end

      # Array holding column symbols that were not present initially.  This is necessary
      # to differentiate between values that were not present and values that were
      # present but equal to nil.
      def missing_initial_values
        @missing_initial_values ||= []
      end

      # Clear the data structures that store the initial values.
      def reset_initial_values
        @initial_values.clear if @initial_values
        @missing_initial_values.clear if @missing_initial_values
      end

      ##### END SEQUEL DIRTY PLUGIN PRIVATE METHODS

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
