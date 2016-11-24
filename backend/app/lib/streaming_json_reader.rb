# Reads a large file of JSON records in a manner that only keeps one record in
# memory at a time.

class StreamingJsonReader

  def initialize(filename)
    @filename = filename

    # The indexes of any records marked as deleted.  We'll skip those on
    # subsequent iterations.
    @deleted_entries = java.util.BitSet.new

    # The total number of records in the underlying file (set upon the first
    # iteration and constant after that)
    @count = nil

    # The record number we've just yielded to the caller's `.each` block
    @record_index = 0

    # Unfortunate to need this: we need a way of skipping the commas between
    # incoming records.
    #
    # Calling parser.nextToken does discard them, but requires catching an
    # exception, which adds a lot of overhead (about 30 seconds per import cycle
    # for 500,000 records instead of ~5 seconds using this method).
    #
    @skip_next_character = org.codehaus.jackson.impl.ReaderBasedParser.java_class.declared_method("_skipWSOrEnd")
    @skip_next_character.accessible = true
  end


  # True if the underlying JSON file was empty
  def empty?
    File.size(@filename) <= 2
  end


  # Fly through our file to work out how many records we have
  def determine_count
    if empty?
      @count = 0
      return
    end

    result = 0

    with_record_stream do |stream|
      mapper = org.codehaus.jackson.map.ObjectMapper.new
      parser = mapper.getJsonFactory.createJsonParser(stream)

      while parser.nextToken
        result += 1
        parser.skipChildren
        skip_comma(parser)
      end
    end

    @count = result
  end


  # Parse and yield each record from our underlying JSON file.  If you call
  # `delete_current` we'll mark the record we just handed you as deleted, and it
  # will be skipped in subsequent iterations.
  def each
    return if empty?

    @record_index = -1
    with_record_stream do |stream|
      mapper = org.codehaus.jackson.map.ObjectMapper.new
      parser = mapper.getJsonFactory.createJsonParser(stream)

      while parser.nextToken
        @record_index += 1

        if @deleted_entries.get(@record_index)
          # Skip this entry
          parser.skipChildren
        else
          result = parser.readValueAs(java.util.Map.java_class)
          yield result
        end

        skip_comma(parser)
      end

      unless @count
        @count = @record_index + 1
      end
    end
  end


  # Mark the record last yielded as deleted.
  def delete_current
    @deleted_entries.set(@record_index)
  end

  # The number of non-deleted records available for reading.
  def count
    if @count
      @count - @deleted_entries.cardinality
    else
      determine_count
    end
  end


  private

  def skip_comma(parser)
    @skip_next_character.invoke(parser)
  end


  def with_record_stream
    stream = java.io.FileReader.new(@filename)
    # Skip the opening [
    stream.read

    begin
      yield stream
    ensure
      stream.close
    end
  end

end
