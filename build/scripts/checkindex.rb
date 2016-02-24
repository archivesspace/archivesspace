require 'java'
require 'tempfile'

class CheckIndex

  LUCENE_JAR_PATTERN = /lucene-core-[0-9].*\.jar$/

  # Extract Lucene from the Solr war file and run CheckIndex.
  def check(args)
    lucene_jar = extract_zip_entry_to_tempfile(find_solr_war) {|entry| entry.get_name =~ LUCENE_JAR_PATTERN}

    begin
      launch_check_index(lucene_jar, args)
    ensure
      lucene_jar.delete
    end
  end


  private

  def find_solr_war
    [File.dirname(__FILE__) + "/../solr-*.war",
     File.dirname(__FILE__) + "/../../wars/solr.war"].each do |glob|
      match = Dir.glob(glob).first
      return match if match
    end

    raise "Solr war file not found"
  end

  def extract_zip_entry_to_tempfile(zipfile, &entry_matcher)
    zip = java.util.zip.ZipFile.new(zipfile)
    tempfile = java.io.File.createTempFile("tempfile", "")
    entries = zip.entries

    found = true
    while entries.has_more_elements
      entry = entries.next_element

      if entry_matcher.call(entry)
        jar_stream = zip.get_input_stream(entry)
        out = java.io.FileOutputStream.new(tempfile)

        copy_stream(jar_stream, out)
        found = true
        break
      end
    end

    if found
      tempfile
    else
      raise "Matching entry not found in zip file"
    end
  end

  def copy_stream(from, to)
    begin
      buf = Java::byte[4096].new

      while (len = from.read(buf)) >= 0
        to.write(buf, 0, len)
      end
    ensure
      to.close
      from.close
    end
  end

  def launch_check_index(lucene_file, args)
    classloader = java.net.URLClassLoader.new([lucene_file.to_url].to_java(java.net.URL))
    classloader.set_default_assertion_status(true)

    java.lang.Thread.current_thread.set_context_class_loader(classloader)

    checkindex = classloader.load_class("org.apache.lucene.index.CheckIndex")
    method = checkindex.get_method("main", [].to_java(java.lang.String).class)

    method.invoke(checkindex, [args.to_java(java.lang.String)].to_java(java.lang.Object))
  end

end


CheckIndex.new.check(ARGV)

