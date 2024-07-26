require 'uri'
require 'net/http'

class TopContainer < Sequel::Model(:top_container)
  include ASModel

  corresponds_to JSONModel(:top_container)

  set_model_scope :repository

  include RestrictionCalculator
  include TouchRecords

  SERIES_LEVELS = ['series']
  OTHERLEVEL_SERIES_LEVELS = ['accession']

  def validate
    validates_unique([:repo_id, :barcode],
                     :message => "A barcode must be unique within a repository")
    map_validation_to_json_property([:repo_id, :barcode], :barcode)

    check = BarcodeCheck.new(Repository[self.class.active_repository].repo_code)

    if !check.valid?(self[:barcode])
      errors.add(:barcode, "Length must be within the range set in configuration")
    end

    super
  end


  def format_barcode
    if self.barcode
      "[#{I18n.t("instance_container.barcode")}: #{self.barcode}]"
    end
  end


  def self.linked_instance_ds
    TopContainer
      .join(:top_container_link_rlshp, :top_container_link_rlshp__top_container_id => :top_container__id)
      .join(:sub_container, :sub_container__id => :top_container_link_rlshp__sub_container_id)
      .join(:instance, :instance__id => :sub_container__instance_id)
  end


  def collections
    @collections ||= calculate_collections
  end

  def calculate_collections
    result = []

    # Resource linked directly
    resource_ids = []
    resource_ids += self.class.resource_ids_linked_directly(self.id)

    # Resource linked via AO
    resource_ids += self.class.resource_ids_linked_via_ao(self.id)

    result += Resource
              .filter(:id => resource_ids.uniq)
              .select_all(:resource)
              .all

    result += Accession
             .join(:instance, :instance__accession_id => :accession__id)
             .join(:sub_container, :sub_container__instance_id => :instance__id)
             .join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
             .filter(:top_container_link_rlshp__top_container_id => self.id)
             .select_all(:accession)
             .all

    result.uniq {|obj| [obj.class, obj.id]}
  end


  def series
    @series ||= calculate_series
  end

  def calculate_series
    linked_aos = ArchivalObject
                 .join(:instance, :instance__archival_object_id => :archival_object__id)
                 .join(:sub_container, :sub_container__instance_id => :instance__id)
                 .join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
                 .filter(:top_container_link_rlshp__top_container_id => self.id)
                 .select(:archival_object__id)

    # Find the top-level archival objects of our selected records.
    # Unfortunately there's no easy way to do this besides walking back up the
    # tree.
    top_level_aos = walk_to_top_level_aos(linked_aos.map {|row| row[:id]})

    ArchivalObject
      .join(:enumeration_value, {:level_enum__id => :archival_object__level_id},
            :table_alias => :level_enum)
      .filter(:archival_object__id => top_level_aos)
      .exclude(:archival_object__component_id => nil)
      .where { Sequel.|(
                 { :level_enum__value => SERIES_LEVELS },
                 Sequel.&({ :level_enum__value => 'otherlevel'},
                          { Sequel.function(:lower, :other_level) => OTHERLEVEL_SERIES_LEVELS }))
    }.select_all(:archival_object)
  end


  def walk_to_top_level_aos(ao_ids)
    result = []
    id_set = ao_ids

    while !id_set.empty?
      next_id_set = []

      ArchivalObject.filter(:id => id_set).select(:id, :parent_id).each do |row|
        if row[:parent_id].nil?
          # This one's a top-level record
          result << row[:id]
        else
          # Keep looking
          next_id_set << row[:parent_id]
        end

        id_set = next_id_set
      end
    end

    result
  end


  def self.find_title_for(series)
    series.respond_to?(:display_string) ? series.display_string : series.title
  end


  def level_display_string(series)
    series.other_level || I18n.t("enumerations.archival_record_level.#{series.level}")
  end

  def series_label
    attached_series = self.series
    if attached_series.empty?
      nil
    else
      attached_series.map {|s| "#{level_display_string(s)} #{s.component_id}" }.join("; ")
    end
  end

  def display_string
    ["#{type ? type.capitalize : ''}", "#{indicator}:", series_label, format_barcode].compact.join(" ").gsub(/:\Z/, '')
  end


  def long_display_string
    container_bit = ["#{type ? type.capitalize : ''}", "#{indicator}", format_barcode].compact.join(" ")
    container_profile = related_records(:top_container_profile)
    container_profile &&= container_profile.name
    location = related_records(:top_container_housed_at).first
    location &&= location.title
    resource = collections.first
    resource &&= [Identifiers.format(Identifiers.parse(resource.identifier)), resource.title].compact.join(", ")

    # Long display string = container type container indicator [barcode: barcode], container profile name, location title, first resource/accession id, first resource/accession title, "series" label
    [container_bit, container_profile, location, resource, series_label].compact.join(", ")
  end

  def find_subcontainer_barcodes
    sub_container_barcodes = ""
    found_subcontainers = related_records(:top_container_link)
    found_subcontainers.each do |found_subcontainer|
      if found_subcontainer.barcode_2
        sub_container_barcodes = sub_container_barcodes + found_subcontainer.barcode_2 + " "
      end
    end
    sub_container_barcodes
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    publication_status = ImpliedPublicationCalculator.new.for_top_containers(objs)

    jsons.zip(objs).each do |json, obj|
      json['is_linked_to_published_record'] = publication_status.fetch(obj)

      json['display_string'] = obj.display_string
      json['long_display_string'] = obj.long_display_string

      json['subcontainer_barcodes'] = obj.find_subcontainer_barcodes

      obj.series.each do |series|
        json['series'] ||= []
        json['series'] << {
          'ref' => series.uri,
          'identifier' => series.component_id,
          'display_string' => find_title_for(series),
          'level_display_string' => obj.level_display_string(series),
          'publish' => !(series.suppressed == 1) && (series.publish == 1)
        }
      end

      obj.collections.each do |collection|
        json['collection'] ||= []
        json['collection'] << {
          'ref' => collection.uri,
          'identifier' => Identifiers.format(Identifiers.parse(collection.identifier)),
          'display_string' => find_title_for(collection)
        }
      end

      if json['exported_to_ils']
        json['exported_to_ils'] = json['exported_to_ils'].getlocal.iso8601
      end
    end

    jsons
  end


  define_relationship(:name => :top_container_housed_at,
                      :json_property => 'container_locations',
                      :contains_references_to_types => proc {[Location]},
                      :class_callback => proc { |clz|
                        clz.instance_eval do
                          plugin :validation_helpers

                          define_method(:validate) do
                            if self[:status] === "previous" && !Location[self[:location_id]].temporary
                              errors.add("container_locations/#{self[:aspace_relationship_position]}/status",
                                         "cannot be previous if Location is not temporary")
                            end

                            super()
                          end

                        end
                      })

  define_relationship(:name => :top_container_profile,
                      :json_property => 'container_profile',
                      :contains_references_to_types => proc {[ContainerProfile]},
                      :is_array => false)

  define_relationship(:name => :top_container_link,
                      :contains_references_to_types => proc {[SubContainer]},
                      :is_array => true)



  # When deleting a top_container, delete all related instances and their subcontainers
  def delete
    related_records(:top_container_link).map {|sub| Instance[sub.instance_id].delete }
    super
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super
    reindex_linked_records
    result
  end


  def reindex_linked_records
    self.class.update_mtime_for_ids([self.id])
  end

  def self.search_stream(params, repo_id, &block)
    query = if params[:q]
              Solr::Query.create_keyword_search(params[:q])
            else
              Solr::Query.create_match_all_query
            end


    max_results = AppConfig.has_key?(:max_top_container_results) ? AppConfig[:max_top_container_results] : 10000

    query.pagination(1, max_results).
      set_repo_id(repo_id).
      set_record_types(params[:type]).
      set_facets(params[:facet]).
      set_filter(params[:filter])

    if params[:filter_term]
      query.set_filter(AdvancedQueryBuilder.from_json_filter_terms(params[:filter_term]))
    end

    query.add_solr_param(:qf, "series_identifier_u_stext collection_identifier_u_stext")

    url = query.to_solr_url
    req = Net::HTTP::Get.new(url.request_uri)

    ASHTTP.start_uri(url) do |http|
      http.request(req, nil) do |response|
        if response.code =~ /^4/
          raise response.body
        end

        block.call(response)
      end
    end
  end


  def self.batch_update(ids, fields)
    fields.each_value(&:strip!)
    out = {}
    begin
      n = self.filter(:id => ids).update(fields.merge({:system_mtime => Time.now, :user_mtime => Time.now}))
      out[:records_updated] = n
    rescue
      out[:error] = $!
    end
    out
  end


  def self.bulk_update_container_profile(ids, container_profile_uri)
    out = {:records_updated => ids.length}

    relationship = TopContainer.find_relationship(:top_container_profile)

    begin
      # Clear all existing container profile links
      relationship.handle_delete(relationship.find_by_participant_ids(TopContainer, ids).map(&:id))

      unless container_profile_uri.empty?
        container_profile = ContainerProfile[JSONModel(:container_profile).id_for(container_profile_uri)]

        raise "Container profile not found: #{container_profile_uri}" if !container_profile

        now = Time.now

        ids.each do |id|
          top_container = TopContainer[id]

          relationship.relate(top_container, container_profile, {
                                :aspace_relationship_position => 1,
                                :system_mtime => now,
                                :user_mtime => now
                              })
        end
      end

      TopContainer.update_mtime_for_ids(ids)

    rescue
      Log.exception($!)

      # This is going to roll back, so nothing will be updated.
      out[:records_updated] = 0
      out[:error] = $!
    end

    out
  end


  def self.bulk_update_location(ids, location_uri)
    out = {:records_updated => ids.length}

    relationship = TopContainer.find_relationship(:top_container_housed_at)

    begin
      relationship.handle_delete(relationship.find_by_participant_ids(TopContainer, ids).select {|v| v.status == 'current'}.map(&:id))

      unless location_uri.empty?
        location = Location[JSONModel(:location).id_for(location_uri)]

        raise "Location not found: #{location_uri}" if !location

        now = Time.now

        ids.each do |id|
          top_container = TopContainer[id]

          relationship.relate(top_container, location, {
                                :status => 'current',
                                :start_date => now.iso8601,
                                :aspace_relationship_position => 0,
                                :system_mtime => now,
                                :user_mtime => now
                              })
        end
      end

      TopContainer.update_mtime_for_ids(ids)

    rescue
      Log.exception($!)

      out[:records_updated] = 0
      out[:error] = $!
    end

    out
  end


  def self.bulk_update_barcodes(barcode_data)
    updated = []

    ids = barcode_data.map {|uri, _| my_jsonmodel.id_for(uri)}

    # null out barcodes to avoid duplicate error as bulk updates are
    # applied
    TopContainer.filter(:id => ids).update(:barcode => nil)

    barcode_data.each do |uri, barcode|
      id = my_jsonmodel.id_for(uri)

      top_container = TopContainer[id]
      top_container.barcode = barcode
      top_container.system_mtime = Time.now

      top_container.save(:columns => [:barcode, :system_mtime])
      updated << id
    end

    TopContainer.update_mtime_for_ids(ids)
    updated
  end


  def self.bulk_update_indicators(indicator_data)
    updated = []

    ids = indicator_data.map {|uri, _| my_jsonmodel.id_for(uri)}

    indicator_data.each do |uri, indicator|
      next unless indicator #skip any records where indicator is not specified

      id = my_jsonmodel.id_for(uri)

      top_container = TopContainer[id]
      top_container.indicator = indicator
      top_container.system_mtime = Time.now

      top_container.save(:columns => [:indicator, :system_mtime])
      updated << id
    end

    TopContainer.update_mtime_for_ids(ids)
    updated
  end


  def self.bulk_update_locations(location_data)
    out = {
      :records_ids_updated => []
    }

    ids = location_data.map {|uri, _| my_jsonmodel.id_for(uri)}

    # remove all 'current' locations
    relationship = TopContainer.find_relationship(:top_container_housed_at)
    relationship.handle_delete(relationship.find_by_participant_ids(TopContainer, ids).select {|v| v.status == 'current'}.map(&:id))

    now = Time.now

    # add new 'current' location for each container
    location_data.each do |uri, location_uri|
    id = my_jsonmodel.id_for(uri)

    begin
      location = Location[JSONModel(:location).id_for(location_uri)]

      raise "Location not found: #{location_uri}" if !location

      top_container = TopContainer[id]

      relationship.relate(top_container, location, {
        :status => 'current',
        :start_date => now.iso8601,
        :aspace_relationship_position => 0,
        :system_mtime => now,
        :user_mtime => now
      })

      out[:records_ids_updated] << id
    rescue
      Log.exception($!)

      out[:error] = $!
    end
  end

    TopContainer.update_mtime_for_ids(ids)

    out[:records_updated] = out[:records_ids_updated].length

    out
  end

  def self.for_barcode(barcode)
    TopContainer[:barcode => barcode, :repo_id => self.active_repository]
  end

  def self.for_indicator(indicator)
    TopContainer[:indicator => indicator, :repo_id => self.active_repository]
  end

  def self.update_mtime_for_ids(ids)
    # Update the Top Container records themselves
    super

    # ... and all of their linked records
    ASModel.all_models.each do |model|
      next unless model.associations.include?(:instance)
      association = model.association_reflection(:instance)
      key = association[:key]
      linked_ids = TopContainer.linked_instance_ds.
                   join(model.table_name, Sequel.qualify(model.table_name, :id) => Sequel.qualify(:instance, key)).
                   filter(:top_container__id => ids).
                   select(Sequel.qualify(model.table_name, :id)).map {|row| row[:id] }
      model.update_mtime_for_ids(linked_ids)

    end
  end

  def self.resource_ids_linked_directly(id)
    Resource
     .join(:instance, :instance__resource_id => :resource__id)
     .join(:sub_container, :sub_container__instance_id => :instance__id)
     .join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
     .filter(:top_container_link_rlshp__top_container_id => id)
     .select(:resource__id)
     .distinct
     .all.map {|row| row[:id]}
  end

  def self.resource_ids_linked_via_ao(id)
    Resource
     .join(:archival_object, :archival_object__root_record_id => :resource__id)
     .join(:instance, :instance__archival_object_id => :archival_object__id)
     .join(:sub_container, :sub_container__instance_id => :instance__id)
     .join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
     .filter(:top_container_link_rlshp__top_container_id => id)
     .select(:resource__id)
     .distinct
     .all.map {|row| row[:id]}
  end

  def self.touch_records(obj)
    [{
      type: Resource,
      ids: (resource_ids_linked_directly(obj.id) + resource_ids_linked_via_ao(obj.id)).uniq
    }]
  end

end
