require 'jsonmodel'

module ASpaceImport
  def self.JSONModel(type)
    @models ||= {}
    @models[type] ||= Class.new(JSONModel::JSONModel(type)) do


      # Need to bypass some validation rules for
      # JSON objects created by an import
      def self.validate(hash, raise_errors = true)
        begin
          super(hash)
        # TODO - speed things up by avoiding this another way
        rescue JSONModel::ValidationException => e

          e.errors.reject! {|path, mssg|
                              e.attribute_types &&
                              e.attribute_types.has_key?(path) &&
                              e.attribute_types[path] == 'ArchivesSpaceDynamicEnum'
                            }

          raise e unless e.errors.empty?
        end
      end


      def initialize(*args)
        super

        # Set a pre-save URI to be dereferenced by the backend
        if self.class.method_defined? :uri
          self.uri = self.class.uri_for(ASpaceImport::Utils.mint_id,
                                        :repo_id => "import")
        end
      end

      def key
        @key ||= self.class.record_type
      end

      def key=(val)
        @key = val
      end

    end

    @models[type]
  end
end
