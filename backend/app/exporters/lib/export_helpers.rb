module ASpaceExport
  # Convenience methods that will work for resource
  # or archival_object models during serialization
  module ArchivalObjectDescriptionHelpers

    def archdesc_note_types
      %w(accruals appraisal arrangement bioghist accessrestrict legalstatus userestrict custodhist altformavail originalsloc fileplan odd acqinfo otherfindaid phystech prefercite processinfo relatedmaterial scopecontent separatedmaterial)
    end


    def did_note_types
      %w(abstract dimensions physdesc langmaterial physloc materialspec physfacet)
    end


    def bibliographies
      self.notes.select {|n| n['jsonmodel_type'] == 'note_bibliography'}
    end


    def indexes
      self.notes.select {|n| n['jsonmodel_type'] == 'note_index'}
    end


    def index_item_type_map
      {
        'corporate_entity'=> 'corpname',
        'genre_form'=> 'genreform',
        'name'=> 'name',
        'occupation'=> 'occupation',
        'person'=> 'persname',
        'subject'=> 'subject',
        'family'=> 'famname',
        'function'=> 'function',
        'geographic_name'=> 'geogname',
        'title'=> 'title'
      }
    end

    def controlaccess_linked_agents(include_unpublished = false)
      unless @controlaccess_linked_agents
        results = []
        linked = self.linked_agents || []
        linked.each_with_index do |link, i|
          if link['role'] == 'creator' || (link['_resolved']['publish'] == false && !include_unpublished)
            results << {}
            next
          end
          role = link['relator'] ? link['relator'] : (link['role'] == 'source' ? 'fmo' : nil)

          agent = link['_resolved'].dup
          sort_name = agent['display_name']['sort_name']
          rules = agent['display_name']['rules']
          source = agent['display_name']['source']
          authfilenumber = agent['display_name']['authority_id']
          content = sort_name.dup

          if link['terms'].length > 0
            content << " -- "
            content << link['terms'].map {|t| t['term']}.join(' -- ')
          end

          node_name = case agent['agent_type']
                      when 'agent_person'; 'persname'
                      when 'agent_family'; 'famname'
                      when 'agent_corporate_entity'; 'corpname'
                      when 'agent_software'; 'name'
                      end

          atts = {}
          atts[:role] = role if role
          atts[:source] = source if source
          atts[:rules] = rules if rules
          atts[:authfilenumber] = authfilenumber if authfilenumber
          atts[:audience] = 'internal' if link['_resolved']['publish'] == false

          results << {:node_name => node_name, :atts => atts, :content => content}
        end

        @controlaccess_linked_agents = results
      end

      @controlaccess_linked_agents
    end


    def controlaccess_subjects
      unless @controlaccess_subjects
        results = []
        linked = self.subjects || []
        linked.each do |link|
          subject = link['_resolved']

          node_name = case subject['terms'][0]['term_type']
                      when 'function'; 'function'
                      when 'genre_form', 'style_period'; 'genreform'
                      when 'geographic', 'cultural_context'; 'geogname'
                      when 'occupation'; 'occupation'
                      when 'topical'; 'subject'
                      when 'uniform_title'; 'title'
                      else; nil
                      end

          next unless node_name

          content = subject['terms'].map {|t| t['term']}.join(' -- ')

          atts = {}
          atts['source'] = subject['source'] if subject['source']
          atts['authfilenumber'] = subject['authority_id'] if subject['authority_id']

          results << {:node_name => node_name, :atts => atts, :content => content}
        end

        @controlaccess_subjects = results
      end

      @controlaccess_subjects
    end


    def archdesc_dates
      unless @archdesc_dates
        results = []
        dates = self.dates || []
        dates.each do |date|
          normal = ""
          unless date['begin'].nil?
            normal = "#{date['begin']}/"
            normal_suffix = (date['date_type'] == 'single' || date['end'].nil? || date['end'] == date['begin']) ? date['begin'] : date['end']
            normal += normal_suffix ? normal_suffix : ""
          end
          type = ( date['date_type'] == 'inclusive' ) ? 'inclusive' : ( ( date['date_type'] == 'single') ? nil : 'bulk')
          content = if date['expression']
                      date['expression']
                    elsif date['end'].nil? || date['end'] == date['begin']
                      date['begin']
                    else
                      "#{date['begin']}-#{date['end']}"
                    end

          atts = {}
          atts[:type] = type if type
          atts[:certainty] = date['certainty'] if date['certainty']
          atts[:normal] = normal unless normal.empty?
          atts[:era] = date['era'] if date['era']
          atts[:calendar] = date['calendar'] if date['calendar']
          atts[:datechar] = date['label'] if date['label']

          results << {:content => content, :atts => atts}
        end

        @archdesc_dates = results
      end

      @archdesc_dates
    end

    def instances_with_digital_objects
      instances = self.instances.select { |inst| inst['digital_object']}.compact
      instances.each do |inst|
        inst['digital_object']['_resolved']['_is_in_representative_instance'] = inst['is_representative']
      end
    end

    def digital_objects
      self.instances_with_digital_objects.map { |instance| instance['digital_object']['_resolved'] }
    end

    def instances_with_sub_containers
      self.instances.select {|inst| inst['sub_container']}.compact
    end
  end


  module LazyChildEnumerations
    def children_indexes
      if @children.count > 0
        (0...@children.count)
      else
        []
      end
    end

    # If we're asked for child 0, grab records 0..PREFETCH_SIZE from the DB
    PREFETCH_SIZE = 20

    def ensure_prefetched(index)
      unless @prefetched_ids && @prefetched_ids.cover?(index)
        new_start = (index / PREFETCH_SIZE) * PREFETCH_SIZE
        new_end = [new_start + PREFETCH_SIZE,
                   @children.count].min

        @prefetched_ids = Range.new(new_start, new_end, true)
        @prefetched_records = @child_class.prefetch(@prefetched_ids.map {|index| @children[index]}, @repo_id)
      end
    end

    def get_child(index)
      if @child_class.respond_to?(:prefetch)
        ensure_prefetched(index)
        rec = @prefetched_records[index % PREFETCH_SIZE]
        @child_class.from_prefetched(@children[index], rec, @repo_id)
      else
        @child_class.new(@children[index], @repo_id)
      end
    end
  end


  module ExportModelHelpers

    def extract_date_string(date)
      if date['expression']
        date['expression']
      elsif date['end'].nil? || date['end'] == date['begin']
        date['begin']
      else
        "#{date['begin']} - #{date['end']}"
      end
    end


    def extract_note_content(note)
      if note['content']
        Array(note['content']).join(" ")
      else
        get_subnotes_by_type(note, 'note_text').map {|sn| sn['content']}.join(" ").gsub(/\n +/, "\n")
      end
    end


    def get_subnotes_by_type(obj, note_type)
      obj['subnotes'].select {|sn| sn['jsonmodel_type'] == note_type}
    end

  end
end
