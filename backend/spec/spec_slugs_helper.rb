require 'pry'


  def clean_slug(slug)
    if slug
      # if the slug contains a slash, completely zero it out.
      # this is intended to revert an entity to use the URI if the ID or name the slug was generated from is a URL.
      slug = "" if slug =~ /\//

      # downcase everything to simplify case sensitivity issues
      slug = slug.downcase

      # replace spaces with underscores
      slug = slug.gsub(" ", "_")

      # remove double hypens
      slug = slug.gsub("--", "")

      # remove single quotes
      slug = slug.gsub("'", "")

      # remove URL-reserved chars
      slug = slug.gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!.]/, "")

      # enforce length limit of 50 chars
      slug = slug.slice(0, 50)

      # replace any multiple underscores with a single underscore
      slug = slug.gsub(/_[_]+/, "_")

      # remove any leading or trailing underscores
      slug = slug.gsub(/^_/, "").gsub(/_$/, "")

      # if slug is numeric, add a leading '__'
      # this is necessary, because numerical slugs will be interpreted as an id by the controller
      if slug.match(/^(\d)+$/)
        slug = slug.prepend("__")
      end

    else
      slug = ""
    end

    return slug
  end


  def format_identifier_separate(id0, id1, id2, id3)
    slug = id0
    slug += "-#{id1}" if id1
    slug += "-#{id2}" if id2
    slug += "-#{id3}" if id3

    return clean_slug(slug)
  end

  # for identifiers that look like this: "[\"987QCXI\",\"WPDX965\",\"244A528553S\",\"187RBJQ\"]"
  def format_identifier_array(array)
  	return "" if array.nil? || array.empty?

  	joined = array.gsub("[", "")
  			          .gsub!("]", "")
  			          .gsub!('"', '')

  	joined = joined.split(",").join("-")

    return clean_slug(joined)
  end