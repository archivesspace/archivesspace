module ArchivalObjectSeries

  def topmost_archival_object
    if self.parent_id
      self.class[self.parent_id].topmost_archival_object
    else
      self
    end
  end


  def series
    top_ao = topmost_archival_object

    if top_ao.has_series_specific_fields?
      top_ao
    else
      nil
    end
  end


  def has_series_specific_fields?
    component_id && (level == "series" || (level == "otherlevel" && other_level.downcase == "accession"))
  end

end
