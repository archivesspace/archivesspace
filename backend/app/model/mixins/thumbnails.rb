module Thumbnails
  def self.included(base)
    base.extend(ClassMethods)
  end

  ThumbnailCandidate =
    Struct.new(:instance_is_representative,
               :digital_object_title,
               :file_version_file_uri,
               :file_version_use_statement,
               :file_version_file_format_name,
               :file_version_xlink_show_attribute,
               :file_version_is_representative,
               :file_version_is_display_thumbnail,
               :file_version_caption) do
    def self.from_hash(h)
      new(*members.map {|m| h.fetch(m)})
    end
  end

  module ClassMethods
    def fetch_thumbnail_candidates(objs)
      candidates = {}

      candidate_query =
        if self.included_modules.include?(FileVersions)
          # Digital Object and Digital Object Components
          self
            .join(:file_version, Sequel.qualify(:file_version, :"#{self.table_name}_id") => Sequel.qualify(self.table_name, :id))
            .filter(Sequel.qualify(self.table_name, :id) => objs.map(&:id))
            .filter(Sequel.qualify(:file_version, :publish) => 1)
            .order(Sequel.qualify(:file_version, :id))
            .select(
              Sequel.as(Sequel.qualify(self.table_name, :id), :record_id),
              Sequel.as(Sequel.qualify(self.table_name, :title), :digital_object_title),
              Sequel.as(Sequel.qualify(:file_version, :file_uri), :file_version_file_uri),
              Sequel.as(Sequel.qualify(:file_version, :use_statement_id), :file_version_use_statement_id),
              Sequel.as(Sequel.qualify(:file_version, :file_format_name_id), :file_version_file_format_name_id),
              Sequel.as(Sequel.qualify(:file_version, :is_representative), :file_version_is_representative),
              Sequel.as(Sequel.qualify(:file_version, :is_display_thumbnail), :file_version_is_display_thumbnail),
              Sequel.as(Sequel.qualify(:file_version, :caption), :file_version_caption),
              Sequel.as(Sequel.qualify(:file_version, :xlink_show_attribute_id), :file_version_xlink_show_attribute_id))

        elsif self.name == 'FileVersion'
          FileVersion
            .filter(Sequel.qualify(:file_version, :id) => objs.map(&:id))
            .order(Sequel.qualify(:file_version, :id))
            .select(
              Sequel.as(Sequel.qualify(:file_version, :id), :record_id),
              Sequel.as(Sequel.qualify(:file_version, :file_uri), :file_version_file_uri),
              Sequel.as(Sequel.qualify(:file_version, :use_statement_id), :file_version_use_statement_id),
              Sequel.as(Sequel.qualify(:file_version, :file_format_name_id), :file_version_file_format_name_id),
              Sequel.as(Sequel.qualify(:file_version, :is_representative), :file_version_is_representative),
              Sequel.as(Sequel.qualify(:file_version, :is_display_thumbnail), :file_version_is_display_thumbnail),
              Sequel.as(Sequel.qualify(:file_version, :caption), :file_version_caption),
              Sequel.as(Sequel.qualify(:file_version, :xlink_show_attribute_id), :file_version_xlink_show_attribute_id))

        elsif self.included_modules.include?(Instances)
          instance_fk_col = :"#{self.table_name}_id"

          Instance
            .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
            .join(:digital_object, Sequel.qualify(:digital_object, :id) => Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
            .join(:file_version, Sequel.qualify(:file_version, :digital_object_id) => Sequel.qualify(:digital_object, :id))
            .filter(Sequel.qualify(:instance, instance_fk_col) => objs.map(&:id))
            .filter(Sequel.qualify(:digital_object, :publish) => 1)
            .filter(Sequel.~(Sequel.qualify(:digital_object, :suppressed) => 1))
            .filter(Sequel.qualify(:file_version, :publish) => 1)
            .order(Sequel.qualify(:file_version, :id))
            .select(
              Sequel.as(Sequel.qualify(:instance, instance_fk_col), :record_id),
              Sequel.as(Sequel.qualify(:instance, :is_representative), :instance_is_representative),
              Sequel.as(Sequel.qualify(:digital_object, :title), :digital_object_title),
              Sequel.as(Sequel.qualify(:file_version, :file_uri), :file_version_file_uri),
              Sequel.as(Sequel.qualify(:file_version, :use_statement_id), :file_version_use_statement_id),
              Sequel.as(Sequel.qualify(:file_version, :file_format_name_id), :file_version_file_format_name_id),
              Sequel.as(Sequel.qualify(:file_version, :is_representative), :file_version_is_representative),
              Sequel.as(Sequel.qualify(:file_version, :is_display_thumbnail), :file_version_is_display_thumbnail),
              Sequel.as(Sequel.qualify(:file_version, :caption), :file_version_caption),
              Sequel.as(Sequel.qualify(:file_version, :xlink_show_attribute_id), :file_version_xlink_show_attribute_id))

        else
          raise "Record type does not support thumbnails: #{self.name}"
        end

      candidate_query.each do |row|
        candidates[row[:record_id]] ||= []
        candidates[row[:record_id]] << ThumbnailCandidate.from_hash(
          :instance_is_representative => row[:instance_is_representative] == 1,
          :digital_object_title => row[:digital_object_title],
          :file_version_file_uri => row[:file_version_file_uri],
          :file_version_use_statement => BackendEnumSource.value_for_id('file_version_use_statement', row[:file_version_use_statement_id]),
          :file_version_file_format_name => BackendEnumSource.value_for_id('file_version_file_format_name', row[:file_version_file_format_name_id]),
          :file_version_xlink_show_attribute => BackendEnumSource.value_for_id('file_version_xlink_show_attribute', row[:file_version_xlink_show_attribute_id]),
          :file_version_is_representative => row[:file_version_is_representative] == 1,
          :file_version_is_display_thumbnail => row[:file_version_is_display_thumbnail] == 1,
          :file_version_caption => row[:file_version_caption]
        )
      end

      candidates
    end

    def find_preferred_thumbnail_candidate(thumbnail_candidates)
      scored_candidates =
        thumbnail_candidates
          .filter { |candidate| is_candidate_a_link?(candidate) }
          .filter { |candidate| is_candidate_embeddable?(candidate) }
          .map { |candidate|
            score =
              if candidate.file_version_is_display_thumbnail
                # If present, use `is_display_thumbnail` flag to explicitly designate a file version as the thumbnail.
                1_000
              elsif candidate.file_version_use_statement == 'image-thumbnail'
                # If none, prefer a file with `use_statement=image-thumbnail`.
                100
              elsif is_candidate_an_image?(candidate)
                # If none, prefer a representative file version if it is an allowed image type.
                10
              else
                0
              end

            # If an instance is marked as representative, prefer its file versions; otherwise, pool all linked DOs.
            if candidate.instance_is_representative && score > 0
              score += 10_000
            end

            [candidate, score]
          }.to_h

      best_score = scored_candidates.values.max

      scored_candidates
        .keys
        .filter { |candidate| scored_candidates[candidate] == best_score }
        .filter { |candidate| scored_candidates[candidate] > 0 }
        .first
    end

    def calculate_image_url(thumbnail_candidates)
      preferred_candidate = find_preferred_thumbnail_candidate(thumbnail_candidates)

      if preferred_candidate
        preferred_candidate.file_version_file_uri
      else
        nil
      end
    end

    def calculate_link_url(thumbnail_candidates)
      scored_candidates =
        thumbnail_candidates
          .filter { |candidate| is_candidate_a_link?(candidate) }
          .map { |candidate|
            score =
              if candidate.file_version_is_representative
                # Prefer the representative file version
                1_000
              elsif candidate.file_version_use_statement != 'image-thumbnail' && candidate.file_version_xlink_show_attribute != 'embed'
                # If none, prefer the first non-thumbnail/embed file version.
                100
              else
                # If none, fall back to the first available.
                10
              end


            # If an instance is marked as representative, prefer its file versions; otherwise, pool all linked DOs.
            if candidate.instance_is_representative
              score += 10_000
            end

            [candidate, score]
          }.to_h

      best_score = scored_candidates.values.max

      best_match =
        scored_candidates
          .keys
          .filter { |candidate| scored_candidates[candidate] == best_score }
          .filter { |candidate| scored_candidates[candidate] > 0 }
          .first

      if best_match
        best_match.file_version_file_uri
      end
    end

    ScoredCaption = Struct.new(:candidate, :caption)
    def calculate_caption(record_json, thumbnail_candidates)
      scored_captions = {}

      # Prefer the thumbnail caption.
      preferred_thumbnail = find_preferred_thumbnail_candidate(thumbnail_candidates)
      if preferred_thumbnail && preferred_thumbnail.file_version_caption
        return preferred_thumbnail.file_version_caption
      end

      thumbnail_candidates.each do |candidate|
        # If absent, use representative’s caption.
        if candidate.file_version_is_representative && candidate.file_version_caption
          scored_captions[ScoredCaption.new(candidate, candidate.file_version_caption)] = 10_000
        end

        # If absent, use the representative’s Digital Object title
        if candidate.file_version_is_representative
          scored_captions[ScoredCaption.new(candidate, candidate.digital_object_title)] ||= 1_000
        end

        # If absent, use the thumbnail’s Digital Object title.
        if candidate == preferred_thumbnail
          scored_captions[ScoredCaption.new(candidate, candidate.digital_object_title)] ||= 100
        end

        # If absent, use the first DO’s title.
        scored_captions[ScoredCaption.new(candidate, candidate.digital_object_title)] ||= 10
      end

      # If an instance is marked as representative, prefer its file versions; otherwise, pool all linked DOs.
      # Bump the score of any representative instance candidates
      scored_captions.keys.each do |scored_caption|
        if scored_caption.candidate.instance_is_representative
          scored_captions[scored_caption] += 100_000
        end
      end

      best_score = scored_captions.values.max

      best_match =
        scored_captions
          .keys
          .filter { |scored_caption| scored_captions[scored_caption] == best_score }
          .filter { |scored_caption| scored_captions[scored_caption] > 0 }
          .first

      if best_match
        return best_match.caption
      end

      # If absent, fall back to the record display string.
      record_json['display_string'] || record_json['title']
    end

    def is_candidate_embeddable?(candidate)
      candidate.file_version_xlink_show_attribute != 'new'
    end

    def is_candidate_a_link?(candidate)
      begin
        uri = URI(candidate.file_version_file_uri)
        if ['http', 'https'].include?(uri.scheme)
          true
        else
          false
        end
      rescue
        false
      end
    end

    def is_candidate_an_image?(candidate)
      AppConfig[:thumbnail_file_format_names].include?(candidate.file_version_file_format_name) &&
        is_candidate_a_link?(candidate)
    end

    def find_a_thumbnail(record_json, thumbnail_candidates)
      if thumbnail_candidates.empty?
        return nil
      end

      image_url = calculate_image_url(thumbnail_candidates)
      link_url = calculate_link_url(thumbnail_candidates)

      if image_url || link_url
        {
          'image_url' => image_url, # placeholder will show if image_url is null
          'link_url' => link_url,
          'caption' => calculate_caption(record_json, thumbnail_candidates),
        }
      else
        nil
      end
    end

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super
      thumbnail_candidates_map = fetch_thumbnail_candidates(objs)

      jsons.zip(objs).each do |json, obj|
        json['thumbnail'] = find_a_thumbnail(json, thumbnail_candidates_map.fetch(obj.id, []))
      end

      jsons
    end
  end
end
