require_relative "bulk_import_parser"

class ImportArchivalObjects < BulkImportParser
  START_MARKER = /ArchivesSpace field code/.freeze

  def initialize(input_file, content_type, current_user, opts)
    super(input_file, content_type, current_user, opts)
    @created_ao_refs = []
    @first_level_aos = []
    @archival_levels = CvList.new("archival_record_level", @current_user)
    @container_types = CvList.new("container_type", @current_user)
    @date_types = CvList.new("date_type", @current_user)
    @date_labels = CvList.new("date_label", @current_user)
    @date_certainty = CvList.new("date_certainty", @current_user)
    @extent_types = CvList.new("extent_extent_type", @current_user)
    @extent_portions = CvList.new("extent_portion", @current_user)
    @instance_types ||= CvList.new("instance_instance_type", @current_user)
    @parents = ParentTracker.new
    @start_marker = START_MARKER
  end

  def initialize_handler_enums
    @cih = ContainerInstanceHandler.new(@current_user)
    @doh = DigitalObjectHandler.new(@current_user)
    @sh = SubjectHandler.new(@current_user)
    @ah = AgentHandler.new(@current_user)
    @lh = LangHandler.new(@current_user)
  end

  # look for all the required fields to make sure they are legit
  # strip all the strings and turn publish and restrictions_flaginto true/false
  def check_row
    err_arr = []
    begin
      # we'll check hierarchical level first, in case there was a parent that didn't get created
      hier = @row_hash["hierarchy"]
      if !hier
        err_arr.push I18n.t("bulk_import.error.hier_miss")
      else
        hier = hier.to_i
        # we bail if the parent wasn't created!
        return I18n.t("bulk_import.error.hier_below_error_level") if (@error_level && hier > @error_level)
        err_arr.push I18n.t("bulk_import.error.hier_zero") if hier < 1
        # going from a 1 to a 3, for example
        if (hier - 1) > @hier
          err_arr.push I18n.t("bulk_import.error.hier_wrong")
          if @hier == 0
            err_arr.push I18n.t("bulk_import.error.hier_wrong_resource")
            raise StopBulkImportException.new(err_arr.join(";"))
          end
        end
        @hier = hier
      end
      missing_title = @row_hash["title"].nil?
      #date stuff: if already missing the title, we have to make sure the date label is valid
      missing_date = [@row_hash["begin"], @row_hash["end"], @row_hash["expression"]].reject(&:nil?).empty?
      if !missing_date
        begin
          label = @date_labels.value((@row_hash["dates_label"] || "creation"))
        rescue Exception => e
          err_arr.push I18n.t("bulk_import.error.invalid_date_label", :what => e.message) if missing_title
          missing_date = true
        end
      end
      err_arr.push I18n.t("bulk_import.error.title_and_date") if (missing_title && missing_date)
      # tree hierachy
      begin
        level = @archival_levels.value(@row_hash["level"])
      rescue Exception => e
        err_arr.push I18n.t("bulk_import.error.level")
      end
    rescue StopBulkImportException => se
      raise
    rescue Exception => e
      Log.error(["UNEXPLAINED EXCEPTION on check row", e.message, e.backtrace, @row_hash].pretty_inspect)
    end
    if err_arr.empty?
      @row_hash.each do |k, v|
        @row_hash[k] = v.strip if !v.nil?
        if k == "publish" || k == "restrictions_flag"
          @row_hash[k] = (v == "1")
        end
      end
    end
    err_arr.join("; ")
  end

  def process_row
    ao = nil
    ret_str = ""
    begin
      resource_match(@resource, @row_hash["ead"], @row_hash["res_uri"])
    rescue Exception => e
      ret_str = e.message
    end
    # mismatch of resource stops all other processing
    if ret_str.empty?
      ret_str = check_row
    end
    raise BulkImportException.new(I18n.t("bulk_import.row_error", :row => @counter, :errs => ret_str)) if !ret_str.empty?
    parent_uri = @parents.parent_for(@row_hash["hierarchy"].to_i)
    begin
      ao = create_archival_object(parent_uri)
      ao = ao_save(ao)
    rescue JSONModel::ValidationException => ve
      # ao won't have been created
      msg = I18n.t("bulk_import.error.second_save_error", :what => ve.errors, :title => ao.title, :pos => ao.position)
      @report.add_errors(msg)
    rescue Exception => e
      Log.error("UNEXPECTED ON SECOND SAVE#{e.message}")
      Log.error(e.backtrace.pretty_inspect)
      Log.error(ASUtils.jsonmodels_to_hashes(ao).pretty_inspect)
      raise BulkImportException.new(e.message)
    end
    @report.add_archival_object(ao) if !ao.nil?
    @parents.set_uri(@hier, ao.uri)
    @created_ao_refs.push ao.uri
    if @hier == 1
      @first_level_aos.push ao.uri
      if @first_one && @start_position
        @need_to_move = (ao.position - @start_position) > 1
        @first_one = false
      end
    end
  end

  private

  # create an archival_object
  def create_archival_object(parent_uri)
    ao = JSONModel(:archival_object).new._always_valid!
    ao.title = @row_hash["title"] if @row_hash["title"]
    ao.dates = create_dates
    #because the date may have been invalid, we should check if there's a title, otherwise bail
    if ao.title.nil? && ao.dates.empty?
      raise BulkImportException.new(I18n.t("bulk_import.error.title_and_date"))
    end
    ao.resource = { "ref" => @resource["uri"] }
    ao.component_id = @row_hash["unit_id"] if @row_hash["unit_id"]
    ao.repository_processing_note = @row_hash["processing_note"] if @row_hash["processing_note"]
    ao.level = @archival_levels.value(@row_hash["level"])
    ao.other_level = @row_hash["other_level"] || "unspecified" if ao.level == "otherlevel"
    ao.publish = @row_hash["publish"]
    ao.restrictions_apply = @row_hash["restrictions_flag"]
    ao.parent = { "ref" => parent_uri } unless parent_uri.nil?
    # handle language issues
    langs = process_langs(ao.publish)
    ao.lang_materials = langs if !langs.empty?
    begin
      ao.extents = process_extents
    rescue Exception => e
      @report.add_errors(e.message)
    end
    errs = handle_notes(ao, @row_hash)
    @report.add_errors(errs) if !errs.empty?
    # we have to save the ao for the display_string
    begin
      ao = ao_save(ao)
    rescue Exception => e
      msg = I18n.t("bulk_import.error.initial_save_error", :title => ao.title, :msg => e.message)
      raise BulkImportException.new(msg)
    end
    ao.instances = create_top_container_instances
    if (dig_instance = @doh.create(@row_hash["digital_object_title"], @row_hash["digital_object_link"], @row_hash["thumbnail"], @row_hash["digital_object_id"], @row_hash["publish"], ao, @report))
      ao.instances ||= []
      ao.instances << dig_instance
    end
    subjs = process_subjects
    subjs.each { |subj| ao.subjects.push({ "ref" => subj.uri }) } unless subjs.empty?
    links = process_agents
    ao.linked_agents = links
    ao
  end

  def create_dates
    dates = []
    cntr = 1
    substr = ""
    until [@row_hash["begin#{substr}"], @row_hash["end#{substr}"], @row_hash["expression#{substr}"]].reject(&:nil?).empty?
      date = create_date(@row_hash["dates_label#{substr}"], @row_hash["begin#{substr}"], @row_hash["end#{substr}"], @row_hash["date_type#{substr}"], @row_hash["expression#{substr}"], @row_hash["date_certainty#{substr}"])
      dates << date if date
      cntr += 1
      substr = "_#{cntr}"
    end
    return dates
  end

  def create_extent(substr)
    ext_str = "Extent: #{@row_hash["portion#{substr}"] || "whole"} #{@row_hash["number#{substr}"]} #{@row_hash["extent_type#{substr}"]} #{@row_hash["container_summary#{substr}"]} #{@row_hash["physical_details#{substr}"]} #{@row_hash["dimensions#{substr}"]}"
    begin
      extent = { "portion" => @extent_portions.value(@row_hash["portion#{substr}"] || "whole"),
                 "extent_type" => @extent_types.value((@row_hash["extent_type#{substr}"])) }
      %w(number container_summary physical_details dimensions).each do |w|
        extent[w] = @row_hash["#{w}#{substr}"] || nil
      end
      ex = JSONModel(:extent).new(extent)
      return ex if test_exceptions(ex, "Extent")
    rescue Exception => e
      @report.add_errors(I18n.t("plugins.aspace-import-excel.error.extent_validation", :msg => e.message, :ext => ext_str))
      return nil
    end
  end

  def process_agents
    agent_links = []
    %w(people corporate_entities families).each do |type|
      num = 1
      while true
        id_key = "#{type}_agent_record_id_#{num}"
        header_key = "#{type}_agent_header_#{num}"
        break if @row_hash[id_key].nil? && @row_hash[header_key].nil?
        link = nil
        begin
          link = @ah.get_or_create(type, @row_hash[id_key], @row_hash[header_key],
                                   @row_hash["#{type}_relator_#{num}"], @row_hash["#{type}_role_#{num}"], @report)
          agent_links.push link if link
        rescue BulkImportException => e
          @report.add_errors(I18n.t("bulk_import.error.process_error", :type => "#{type} Agent", :num => num, :why => e.message))
        end
        num += 1
      end
    end
    agent_links
  end

  def initialize_info
    super
    @ao = nil
    aoid = @opts[:aoid] || nil
    @resource_level = (aoid.nil? || aoid.strip.empty?)
    @first_one = false # to determine whether we need to worry about positioning
    if @resource_level
      @parents.set_uri(0, nil)
      @hier = 0
    else
      @ao = ArchivalObject.to_jsonmodel(Integer(aoid))
      @start_position = @ao.position
      parent = @ao.parent # we need this for sibling/child disabiguation later on
      @parents.set_uri(0, (parent ? ASUtils.jsonmodels_to_hashes(parent)["ref"] : nil))
      @parents.set_uri(1, @ao.uri)
      @first_one = true
    end
  end

  def create_top_container_instances
    instances = []
    cntr = 1
    substr = ""
    until @row_hash["cont_instance_type#{substr}"].nil? && @row_hash["type_1#{substr}"].nil? && @row_hash["barcode#{substr}"].nil?
      begin
        subcont = { "type_2" => @row_hash["type_2#{substr}"],
                    "indicator_2" => @row_hash["indicator_2#{substr}"],
                    "type_3" => @row_hash["type_3#{substr}"],
                    "indicator_3" => @row_hash["indicator_3#{substr}"] }

        instance = @cih.create_container_instance(@row_hash["cont_instance_type#{substr}"],
                                                  @row_hash["type_1#{substr}"], @row_hash["indicator_1#{substr}"], @row_hash["barcode#{substr}"], @resource["uri"], @report, subcont)
      rescue Exception => e
        @report.add_errors(I18n.t("bulk_import.error.no_tc", number: cntr.to_s, why: e.message))
        instance = nil
      end
      cntr += 1
      substr = "_#{cntr}"
      instances << instance if instance
    end
    return instances
  end

  def process_extents
    extents = []
    cntr = 1
    substr = ""
    until @row_hash["number#{substr}"].nil? && @row_hash["extent_type#{substr}"].nil?
      extent = create_extent(substr)
      extents << extent if extent
      cntr += 1
      substr = "_#{cntr}"
    end
    return extents
  end

  def process_langs(publish)
    langs = []
    cntr = 1
    substr = ""
    until @row_hash["l_lang#{substr}"].nil? && @row_hash["l_langscript#{substr}"].nil? && @row_hash["n_langmaterial#{substr}"].nil?
      pubnote = @row_hash["p_langmaterial#{substr}"]
      if pubnote.nil?
        pubnote = publish
      else
        pubnote = (pubnote == "1")
      end
      lang = @lh.create_language(@row_hash["l_lang#{substr}"], @row_hash["l_langscript#{substr}"], @row_hash["n_langmaterial#{substr}"], pubnote, @report)
      langs.concat(lang) if !lang.empty?
      @row_hash["n_langmaterial#{substr}"] = nil
      cntr += 1
      substr = "_#{cntr}"
    end
    return langs
  end

  def process_subjects
    ret_subjs = []
    repo_id = @repository.split("/")[2]
    (1..10).each do |num|
      unless @row_hash["subject_#{num}_record_id"].nil? && @row_hash["subject_#{num}_term"].nil?
        subj = nil
        begin
          subj = @sh.get_or_create(@row_hash["subject_#{num}_record_id"],
                                   @row_hash["subject_#{num}_term"], @row_hash["subject_#{num}_type"],
                                   @row_hash["subject_#{num}_source"], repo_id, @report)
          ret_subjs.push subj if subj
        rescue Exception => e
          @report.add_errors(I18n.t("bulk_import.error.process_error", :type => "Subject", :num => num, :why => e.message))
        end
      end
    end
    ret_subjs
  end
end
