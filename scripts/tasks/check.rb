# frozen_string_literal: true

module Check
  def self.run(checker)
    checker.check
    if checker.issues.count.zero?
      puts('No issues found!')
    else
      abort(JSON.pretty_generate(checker.issues))
    end
  end

  class Locales
    attr_reader :directories, :issues, :locales
    def initialize(directories)
      @directories = directories
      @issues = {}
      @locales = {}
      arrange_locales
    end

    def check
      locales.each do |_, compare|
        locale_en = load_keys(compare[:eng])
        compare[:others].each do |other|
          missing = compare_locales(locale_en, load_keys(other))
          next unless missing.any?

          issues[other] = missing
        end
      end
      issues
    end

    private

    # gather locales by path
    def arrange_locales
      directories.each do |locale_dir|
        locales[locale_dir] = { eng: nil, others: [] }
        Dir[File.join(locale_dir, '*.yml')].each do |locale|
          if locale =~ /en.yml$/
            locales[locale_dir][:eng] = locale
          else
            locales[locale_dir][:others] << locale
          end
        end
      end
    end

    # get set of missing (flattened) keys comparing two locales files
    def compare_locales(locale1, locale2)
      (locale2 - locale1).concat(locale1 - locale2)
    end

    #  https://stackoverflow.com/questions/28194836/rails-find-missing-keys-between-different-locales-yml-files
    def flatten_keys(hash, prefix = '')
      keys = []
      hash.keys.each do |key|
        if hash[key].is_a? Hash
          current_prefix = prefix + "#{key}."
          keys << flatten_keys(hash[key], current_prefix)
        else
          keys << "#{prefix}#{key}"
        end
      end
      prefix == '' ? keys.flatten : keys
    end

    # get flattened set of keys from YAML
    def load_keys(file)
      yaml = YAML.load(File.read(file))
      flatten_keys(yaml[yaml.keys.first])
    end
  end

  class Gems
    attr_reader :gems, :issues, :path
    def initialize(path)
      @gems = Hash.new { |h, k| h[k] = [] }
      @issues = []
      @path = path
    end

    def check
      Dir[path].each do |gem_path|
        name, version = parse_gem_path(gem_path)
        gems[name] << version
      end
      issues.append(gems.select { |_, v| v.count > 1 })
    end

    private

    # get [name, version] from a gem path
    def parse_gem_path(gem_path)
      parts = gem_path.split(File::SEPARATOR)[-1].split('-')
      if parts[-1] == 'java'
        name = parts[0..-3]
        version = parts[-2]
      else
        name = parts[0..-2]
        version = parts[-1]
      end
      [name.join('-'), version]
    end
  end
end
