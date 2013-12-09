class Converter

  def initialize(input_file)
    @input_file = input_file
    @batch = ASpaceImport::RecordBatch.new
  end

  def get_output_path
    @batch.get_output_path
  end

end
