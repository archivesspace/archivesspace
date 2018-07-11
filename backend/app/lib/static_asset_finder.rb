class StaticAssetFinder

  def initialize(base)
    static_dir = File.join(ASUtils.find_base_directory, base)

    @valid_paths = Dir[File.join(static_dir, "**", "*")].
                            select {|path| File.exist?(path) && File.file?(path)}
  end


  def find(query)
    match = if query && !query.empty?
              @valid_paths.find {|path| path.end_with?(query)}
            end

    raise NotFoundException.new("File not found: #{query} in #{@valid_paths}") unless match
     

    match
  end

  def find_all(query)
    match = if query && !query.empty?
              @valid_paths.select {|path| path.end_with?(query)}
            end

    raise NotFoundException.new("File not found: #{query} in #{@valid_paths}") unless match
     

    match
  end


  def find_by_extension(extension)
    @valid_paths.select { |path| File.extname(path) == extension }
  end

end
