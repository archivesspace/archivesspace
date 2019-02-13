require 'yaml'

def locales_directories
  locales_dirs = []
  locales_dirs.push(Dir.glob("common/**/locales/**/"))
  locales_dirs.push(Dir.glob("frontend/**/locales/**/"))
  locales_dirs.push(Dir.glob("public/**/locales/**/"))
  locales_dirs.flatten!
end

def reports_dirs
  reports_files = Dir.glob("reports/**/*.yml")
  rpts_dirs = []
  reports_files.each do | rpt |
    rpts_dirs.push(rpt.split('/')[0..-2].join('/') + '/')
  end
  rpts_dirs.uniq!
end

def compare_keys first_file_info, second_file_info
  puts "Comparing #{first_file_info[:file_location]} to #{second_file_info[:file_location]}"
  first_translations = {}
  second_translations = {}
  first_file = Hash.new
  second_file = Hash.new
  deltas_file = Hash.new
  File.open( first_file_info[:file_location] ) { |yf| first_file = YAML.load(yf) }
  process_hash(first_translations, '', first_file[first_file_info[:root]])
  File.open( second_file_info[:file_location] ) { |yf| second_file = YAML.load(yf) }
  process_hash(second_translations, '', second_file[second_file_info[:root]])
  first_keys_sort = first_translations.keys.sort
  second_keys_sort = second_translations.keys.sort
  if first_keys_sort == second_keys_sort
    puts "They have the same entries"
  elsif first_translations.keys.count > second_translations.keys.count
    puts "Difference #{(first_keys_sort - second_keys_sort)}"
  else
    puts "Difference #{(second_keys_sort - first_keys_sort)}"
  end
end

def process_hash(translations, current_key, hash)
  hash.each do |new_key, value|
    combined_key = [current_key, new_key].delete_if { |k| k.to_s.empty? }.join('.')
    if value.is_a?(Hash)
      process_hash(translations, combined_key, value)
    else
      translations[combined_key] = value
    end
  end
end

def compare_files(dirs)
  first_file_info = {}
  first_file_info[:root] = 'en'
  dirs.each do | dir |
    first_file_info[:file_location] = "#{dir}en.yml"
    Dir.glob("#{dir}*.yml").each do | y |
      if (y !~ /en\.yml/)
        second_file_info = {}
        file_name = y.split('/')[-1]
        second_file_info[:file_location] = dir + file_name
        second_file_info[:root] = file_name.split('.')[0]
        compare_keys first_file_info, second_file_info
      end
    end
  end
end

locales_res = compare_files(locales_directories)
reports_res = compare_files(reports_dirs)
