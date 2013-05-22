module ClassificationHelper

  def self.format_classification(path_to_root)
    id_string =  path_to_root.map {|node| node['identifier']}.join(I18n.t("classification.id_separator"))
    "#{id_string} #{path_to_root.last['title']}"
  end

end
