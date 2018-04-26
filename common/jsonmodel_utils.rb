# Contains methods to manipulate JSON representations

module JSONModel

  # it's possible for a node to have publish = true and at the same time have an ancestor with publish = false.
  # this method traverses a JSONModel and sets publish = false for any node that has an ancestor with publish = false.
  def self.set_publish_flags!(jsonmodel) 
    # if the parameter is not a hash, then it's a JSONModel object and the data we want is in @data.
    if(jsonmodel.is_a?(Hash))
      traverse!(jsonmodel)
    else
      traverse!(jsonmodel.data)
    end
  end

  # returns an ARK URL for a JSON model
  def self.get_ark_url(id, type)
    case type
    when :digital_object
      ark = ARKIdentifier.first(:digital_object_id => id)
      return "#{AppConfig[:ark_url_prefix]}/ark:/#{AppConfig[:ark_naan]}/#{ark.id}" if ark
    when :reousrce
    when :accession
    end
  end

  private

  def self.traverse!(ds, ancestor_publish = nil)

    # during traversal, if we encounter a hash with a "publish" key
    # if ancestor_publish is true
    #    set ancestor_publish to this value for the subtree
    #    do not change value
    # if ancestor_publish is false, an ancestor was set to publish = false
    #    change this value to false
    #    set ancestor_publish_value to false for the subtree

    if ds.is_a?(Hash) && ds.has_key?('publish')
      if ancestor_publish == true || ancestor_publish.nil?
        ancestor_publish = ds['publish']
      elsif ancestor_publish == false
        ds['publish'] = false
      end
    end

    # iterate and search over this subtree
    if ds.is_a?(Hash)
      ds.each do |key, value|
        if value.is_a?(Hash) || value.is_a?(Array)
          traverse!(value, ancestor_publish)
        end
      end
    end

    if ds.is_a?(Array)
      ds.each do |value|
        if value.is_a?(Hash) || value.is_a?(Array)
          traverse!(value, ancestor_publish)
        end
      end
    end
  end
end
