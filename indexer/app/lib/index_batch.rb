# Represents a batch of documents that are being prepared for indexing.
#
# A batch is append-only (documents can't be changed or removed once added).

require 'tempfile'

class IndexBatch

  SEPARATORS = [",\n", "]\n"]

  def initialize
    @bytes = 0
    @record_count = 0
    @closed = false

    @filestore = ASUtils.tempfile('index_batch')

    # Don't mess up our line breaks under Windows!
    @filestore.binmode

    self.write("[\n")
  end


  def close
    unless @closed
      @closed = true
      self.write("]\n")
    end
  end


  def write(s)
    @bytes += s.bytes.count
    @filestore.write(s)
    @filestore.flush
  end


  def <<(doc)
    json = ASUtils.to_json(doc)

    if @record_count > 0
      self.write(",\n")
    end

    self.write(json)
    self.write("\n")

    @record_count += 1
  end

  def rewind
    @filestore.rewind
    @filestore.readline         # skip the opening [
  end

  def map(&block)
    self.rewind

    result = []
    @filestore.each_line("\n") do |line|
      result << block.call(ASUtils.json_parse(line)) if !SEPARATORS.include?(line)
    end

    result
  end


  def each(&block)
    self.rewind

    @filestore.each_line("\n") do |line|
      block.call(ASUtils.json_parse(line)) if !SEPARATORS.include?(line)
    end

    self
  end


  def to_json_stream
    self.close
    @filestore.close

    # Open with "b" to avoid converting \n to \r\n on Windows
    File.open(@filestore.path, "rb")
  end


  def byte_count
    @bytes
  end

  def concat(docs)
    docs.each do |doc|
      self << doc
    end
  end


  def empty?
    @record_count == 0
  end


  def length
    @record_count
  end


  def destroy
    self.close
    @filestore.close
    @filestore.unlink
  end

end
