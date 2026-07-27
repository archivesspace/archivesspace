require 'base64'
require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'rubygems/package'
require 'stringio'
require 'uri'
require 'zlib'

# Updates the IIIF viewers that ArchivesSpace bundles and serves as static
# files.
#
# Each of SUI and PUI apps serves its own static files, so every bundled viewer exists twice:
# once for the staff UI and once for the public UI.
module IIIFViewers

  REGISTRY = 'https://registry.npmjs.org'.freeze

  MIRADOR = {
    :name => 'Mirador',
    :package => 'mirador',
    :destination_directories => ['frontend/public/mirador', 'public/public/mirador'],
    # Mirador ships a self-contained UMD bundle, so self-hosting it needs only
    # that file plus the license.
    :files_mapping => {
      'dist/mirador.min.js' => 'mirador.min.js',
      'LICENSE' => 'LICENSE.txt'
    },
    # Maintained by ArchivesSpace rather than copied from the package, so an
    # update must leave these alone.
    :ours => ['index.html', 'README.md'],
    # The bundle index.html loads, and the global it calls Mirador.viewer() on.
    :entry => 'dist/mirador.min.js',
    :global => 'Mirador'
  }.freeze

  # Universal Viewer's UMD build is code split: umd/UV.js loads other files from umd/ and expects them to be present.

  # Unlike Mirador, the host page (uv.html) comes from the package rather than
  # from ArchivesSpace, so it is replaced too.
  UNIVERSAL_VIEWER = {
    :name => 'Universal Viewer',
    :package => 'universalviewer',
    :destination_directories => ['frontend/public/uv', 'public/public/uv'],
    :files_mapping => {
      'dist/uv.html' => 'uv.html',
      'dist/uv.css' => 'uv.css',
      'dist/favicon.ico' => 'favicon.ico',
      'dist/uv-iiif-config.json' => 'uv-iiif-config.json',
      'dist/uv-youtube-config.json' => 'uv-youtube-config.json',
      'LICENSE.txt' => 'LICENSE.txt'
    },
    # Directories copied whole: path inside the package => name on disk.
    :trees => { 'dist/umd' => 'umd' },
    :ours => ['README.md'],
    :entry => 'dist/umd/UV.js',
    :global => 'UV',

    # IIIF.viewer_url builds the embed URL as uv.html#?manifest=<uri>, which
    # uv.html reads through UV's IIIFURLAdapter.
    :requires => { 'dist/uv.html' => ['IIIFURLAdapter'] }
  }.freeze

  def self.update(viewer, version: nil)
    version ||= latest_version(viewer[:package])
    current = bundled_versions(viewer)

    puts "#{viewer[:name]}: bundled #{current.values.uniq.join(', ')}, updating to #{version}"

    dist = distribution(viewer[:package], version)
    tarball = download(dist.fetch('tarball'))
    verify_integrity!(tarball, dist)

    files = extract(tarball, viewer)
    check_compatibility!(viewer, files)

    viewer[:destination_directories].each { |dir| install(viewer, dir, files, version) }

    puts "#{viewer[:name]} #{version} installed. Review the diff, then run the " \
         'IIIF feature specs before committing.'
  end

  # The version each directory currently records in its README.
  def self.bundled_versions(viewer)
    viewer[:destination_directories].each_with_object({}) do |dir, versions|
      readme = File.join(dir, 'README.md')
      match = File.exist?(readme) ? File.read(readme)[/^- Version: \*\*([^*]+)\*\*/, 1] : nil
      versions[dir] = match || 'unknown'
    end
  end

  def self.latest_version(package)
    fetch_json("#{REGISTRY}/#{package}").fetch('dist-tags').fetch('latest')
  end

  def self.distribution(package, version)
    fetch_json("#{REGISTRY}/#{package}/#{version}").fetch('dist')
  end

  def self.fetch_json(url)
    JSON.parse(get(url).body)
  end

  def self.download(url)
    get(url).body
  end

  def self.get(url)
    response = Net::HTTP.get_response(URI.parse(url))
    raise "Failed to fetch #{url}: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def self.verify_integrity!(tarball, dist)
    if dist['integrity']
      algorithm, expected = dist['integrity'].split('-', 2)
      actual = Base64.strict_encode64(Digest.const_get(algorithm.upcase).digest(tarball))
      raise "Tarball failed #{algorithm} integrity check" unless actual == expected
    elsif dist['shasum']
      actual = Digest::SHA1.hexdigest(tarball)
      raise 'Tarball failed shasum check' unless actual == dist['shasum']
    else
      raise 'Registry published no checksum for this version'
    end
  end

  # npm tarballs hold everything under a top level "package" directory. Returns
  # the file contents we need, keyed by path within the package.
  def self.extract(tarball, viewer)
    wanted = viewer[:files_mapping].keys
    prefixes = trees(viewer).keys.map { |tree| "#{tree}/" }
    found = {}

    Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(tarball))) do |tar|
      tar.each do |entry|
        next unless entry.file?

        path = entry.full_name.sub(%r{\A[^/]+/}, '')
        next unless wanted.include?(path) || prefixes.any? { |prefix| path.start_with?(prefix) }

        found[path] = entry.read
      end
    end

    missing = wanted - found.keys
    missing += prefixes.reject { |prefix| found.each_key.any? { |path| path.start_with?(prefix) } }
    raise "Package is missing #{missing.join(', ')}" unless missing.empty?

    found
  end

  # A new release could drop the UMD build, rename the global the host page
  # loads, or change how the host page reads the manifest.
  def self.check_compatibility!(viewer, files)
    preamble = files.fetch(viewer[:entry])[0, 1000]

    unless preamble.include?(viewer[:global]) && preamble.include?('define')
      incompatible!(viewer, "#{viewer[:entry]} does not look like a UMD bundle exposing " \
                            "#{viewer[:global]}, which the host page initializes the viewer through")
    end

    viewer.fetch(:requires, {}).each do |path, tokens|
      absent = tokens.reject { |token| files.fetch(path).include?(token) }
      next if absent.empty?

      incompatible!(viewer, "#{path} no longer mentions #{absent.join(', ')}, which the " \
                            'ArchivesSpace embed URL relies on')
    end
  end

  def self.incompatible!(viewer, problem)
    raise "#{viewer[:name]} cannot be bundled as is: #{problem}. Check the release " \
          'notes and updating task to match the new build ' \
          'before bundling this version.'
  end

  def self.trees(viewer)
    viewer.fetch(:trees, {})
  end

  def self.install(viewer, dir, files, version)
    FileUtils.mkdir_p(dir)

    viewer[:files_mapping].each do |source, target|
      File.binwrite(File.join(dir, target), files.fetch(source))
      puts "  #{dir}/#{target}"
    end

    trees(viewer).each { |source, target| install_tree(dir, target, files, source) }

    prune(viewer, dir)
    record_version(dir, version)
  end

  def self.install_tree(dir, target, files, source)
    path = File.join(dir, target)
    FileUtils.rm_rf(path)

    written = files.each_with_object([]) do |(package_path, content), done|
      next unless package_path.start_with?("#{source}/")

      destination = File.join(path, package_path.delete_prefix("#{source}/"))
      FileUtils.mkdir_p(File.dirname(destination))
      File.binwrite(destination, content)
      done << destination
    end

    puts "  #{dir}/#{target}/ (#{written.size} files)"
  end

  def self.prune(viewer, dir)
    keep = viewer[:files_mapping].values + trees(viewer).values + viewer[:ours]

    Dir.children(dir).sort.each do |name|
      next if keep.include?(name)

      FileUtils.rm_rf(File.join(dir, name))
      puts "  removed stale #{dir}/#{name}"
    end
  end

  def self.record_version(dir, version)
    readme = File.join(dir, 'README.md')
    return unless File.exist?(readme)

    content = File.read(readme)
    pattern = /^(- Version: \*\*)[^*]+(\*\*)/

    unless content.match?(pattern)
      puts "  NOTE: no version line to update in #{readme}"
      return
    end

    File.write(readme, content.sub(pattern, "\\1#{version}\\2"))
    puts "  #{readme} (version: #{version})"
  end
end
