require_relative "../../../migrations/lib/utils"

module ImportHelpers
  
  def handle_import(batch, progress_ticker)

    begin
      batch.process(progress_ticker)
      json_response({:saved => batch.saved_uris}, 200)
    end
  end
  

  class ImportException < StandardError
    attr_accessor :invalid_object
    attr_accessor :message
    attr_accessor :error

    def initialize(opts)
      @invalid_object = opts[:invalid_object]
      @error = opts[:error]
    end

    def to_hash
      hsh = {'record_title' => nil, 'record_type' => nil, 'error_class' => self.class.name, 'errors' => []}
      hsh['record_title'] = @invalid_object[:title] ? @invalid_object[:title] : "unknown or untitled"
      hsh['record_type'] = @invalid_object.jsonmodel_type ? @invalid_object.jsonmodel_type : "unknown type"

      if @error.respond_to?(:errors)
        @error.errors.each {|e| hsh['errors'] << e}
      else
        hsh['errors'] = @error.inspect
      end
      hsh
    end

    def to_s
      "#<:ImportException: #{{:invalid_object => @invalid_object, :error => @error}.inspect}>"
    end
  end

end
