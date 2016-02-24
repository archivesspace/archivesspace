require 'json'
require 'digest/sha1'

Sequel.extension :pagination


class UserDefinedFieldMigrator

  EXTERNAL_ID_MAPPING = [
    {
      :source => "Archivists Toolkit Database::RESOURCE",
      :aspace_column => :resource_id,
      :at_column => :resourceId
    },
    {
      :source => "Archivists Toolkit Database::RESOURCE_COMPONENT",
      :aspace_column => :archival_object_id,
      :at_column => :resourceComponentId
    },
  ]


  def dry_run?
    !AppConfig.has_key?(:user_defined_field_migrate_dry_run) || AppConfig[:user_defined_field_migrate_dry_run]
  end


  def apply_update(top_container, container_data)
    Log.info("Applying additional container data for top container: #{top_container.values}: #{container_data}")

    update_values = {
      :ils_holding_id => container_data.voyager_holding_id,
      :exported_to_ils => Time.now,
    }

    profile = container_data.container_profile


    if dry_run?
      Log.info("DRY RUN: Update values #{update_values.inspect}")
      Log.info("DRY RUN: Using container profile: #{profile.values}") if profile
      if container_data.voyager_bib_id
        Log.info("DRY RUN: Linked records needed user-defined fields: #{find_records_needing_user_defined_fields(top_container).inspect}")
      end
    else
      update_values.each do |property, value|
        top_container[property] = value
      end

      top_container.save

      if profile
        TopContainer.find_relationship(:top_container_profile).relate(top_container, profile,
                                                                      {
                                                                        :aspace_relationship_position => 0,
                                                                        :system_mtime => Time.now,
                                                                        :user_mtime => Time.now
                                                                      })
      end

      if container_data.voyager_bib_id
        models_to_update = find_records_needing_user_defined_fields(top_container)

        models_to_update.each do |model, ids|
          userdefined_link_column = model.association_reflection(:user_defined)[:key]

          ids.each do |id|
            udf = UserDefined[userdefined_link_column => id]

            if udf

              if udf[:string_2]
                if udf[:string_2] == container_data.voyager_bib_id
                  next
                else
                  Log.warn("Mismatch in Bib ID for #{model} #{id} linked to Top Container #{top_container.id}")
                end
              end

              udf[:string_2] = container_data.voyager_bib_id
              udf.save
            else
              now = Time.now
              UserDefined.create(userdefined_link_column => id,
                                 :string_2 => container_data.voyager_bib_id,
                                 :json_schema_version => 1,
                                 :system_mtime => now,
                                 :user_mtime => now,
                                 :created_by => 'admin',
                                 :last_modified_by => 'admin',
                                 :create_time => now)
            end
          end
        end
      end
    end
  end


  def migrate

    raise "No target ArchivesSpace repository was specified.  You will need to set AppConfig[:at_target_aspace_repo]" unless AppConfig.has_key?(:at_target_aspace_repo)

    repo = Repository[:repo_code => AppConfig[:at_target_aspace_repo]]

    raise "No repository found for repo_code '#{AppConfig[:at_target_aspace_repo]}'" if !repo


    set_up_temp_tables
    begin
      Log.info("Preloading top container mappings")
      preload_top_container_mappings
      Log.info("Done!")

      Sequel.connect(AppConfig[:at_db_url]) do |db|
        at = ArchivistsToolkit.new(db)

        RequestContext.open(:repo_id => repo.id,
                            :is_high_priority => false,
                            :current_username => "admin") do

          total_count = TopContainer.filter(:repo_id => repo.id).count
          count = 0
          TopContainer.filter(:repo_id => repo.id).each do |top_container|
            count += 1

            if (count % 100) == 0
              Log.info("Processing top container #{count} of #{total_count}")
            end

            DB.open do |db|

              relationship = TopContainer.find_relationship(:top_container_link)

              subcontainers = relationship.filter(:top_container_id => top_container.id).select(:sub_container_id)
              instances = Instance.filter(:id => SubContainer.filter(:id => subcontainers).select(:instance_id))

              got_a_match = false
              container_data = nil

              EXTERNAL_ID_MAPPING.each do |mapping|

                at_record_ids = db[:udf_mig_tc_to_extid].
                                filter(:top_container_id => top_container.id).
                                select(mapping[:aspace_column]).
                                map {|row| row[mapping[:aspace_column]]}

                next if at_record_ids.empty?

                at_containers = at.find_matching_containers(mapping[:at_column], at_record_ids, top_container)

                if at_containers.empty?
                  true # No match, but maybe we'll get it in the next round.
                elsif (at_containers - [:no_data]).length > 1
                  Log.error("Ambiguous containers for #{top_container.values.inspect}: #{at_containers.inspect}")

                  # Still counts as getting a match for logging purposes, but it's a lousy match!
                  got_a_match = true
                else
                  # puts "#{top_container.id}: Good!"
                  got_a_match = true
                  container_data = (at_containers - [:no_data]).first
                end
              end

              if got_a_match
                if container_data
                  apply_update(top_container, container_data)
                end
              else
                if db[:udf_mig_tc_to_extid].
                    filter(:top_container_id => top_container.id).
                    where { Sequel.~(:accession_id => nil) }.
                    count > 0
                  # That's OK.  The top container is linked to an accession, so
                  # not a huge problem that we didn't find a match.
                  true
                else
                  Log.error("No matching containers for #{top_container}: #{top_container.values.inspect}")
                end
              end
            end
          end
        end
      end
    ensure
      tear_down_temp_tables
    end
  end


  private


  def find_records_needing_user_defined_fields(top_container)
    models_to_update = {}

    ASModel.all_models.each do |model|
      if model.included_modules.include?(Instances)
        instance_link_column = model.association_reflection(:instance)[:key]

        id_set = TopContainer.linked_instance_ds.
                 filter(:top_container__id => top_container.id).
                 where { Sequel.~(instance_link_column => nil) }.
                 select(instance_link_column).
                 map {|row| row[instance_link_column]}

        if model.included_modules.include?(TreeNodes)
          models_to_update[model.root_model] ||= []
          models_to_update[model.root_model].concat(model.filter(:id => id_set).select(:root_record_id).distinct.map(&:root_record_id))
        else
          models_to_update[model] ||= []
          models_to_update[model].concat(model.filter(:id => id_set).select(:id).map(&:id))
        end
      end
    end

    models_to_update
  end


  def set_up_temp_tables
    tear_down_temp_tables

    # Create some scratch tables to work with
    DB.open do |db|

      db.create_table :udf_mig_tc_to_extid do
        primary_key :id
        Integer :top_container_id, :index => true
        Integer :accession_id
        Integer :resource_id
        Integer :archival_object_id
      end

    end
  end


  def preload_top_container_mappings
    DB.open do |db|
      db.run("insert into udf_mig_tc_to_extid (top_container_id, archival_object_id)" +
             " SELECT top_container_link_rlshp.top_container_id, external_id.external_id" +
             " FROM external_id" +
             " INNER JOIN instance ON (instance.archival_object_id = external_id.archival_object_id)" +
             " INNER JOIN sub_container ON (sub_container.instance_id = instance.id)" +
             " INNER JOIN top_container_link_rlshp ON (top_container_link_rlshp.sub_container_id = sub_container.id)" +
             " WHERE ((external_id.source = 'Archivists Toolkit Database::RESOURCE_COMPONENT') AND" +
             "   (external_id.archival_object_id IS NOT NULL))")

      db.run("insert into udf_mig_tc_to_extid (top_container_id, resource_id)" +
             " SELECT top_container_link_rlshp.top_container_id, external_id.external_id" +
             " FROM external_id" +
             " INNER JOIN instance ON (instance.resource_id = external_id.resource_id)" +
             " INNER JOIN sub_container ON (sub_container.instance_id = instance.id)" +
             " INNER JOIN top_container_link_rlshp ON (top_container_link_rlshp.sub_container_id = sub_container.id)" +
             " WHERE ((external_id.source = 'Archivists Toolkit Database::RESOURCE') AND" +
             "   (external_id.resource_id IS NOT NULL))")

      # We don't actually have an external ID for accessions, but we don't need
      # one here anyway.  We're just recording whether each top_container is
      # linked to an accession.
      db.run("insert into udf_mig_tc_to_extid (top_container_id, accession_id)" +
             " SELECT top_container_link_rlshp.top_container_id, 1" +
             " FROM accession" +
             " INNER JOIN instance ON (instance.accession_id = accession.id)" +
             " INNER JOIN sub_container ON (sub_container.instance_id = instance.id)" +
             " INNER JOIN top_container_link_rlshp ON (top_container_link_rlshp.sub_container_id = sub_container.id)")

    end
  end


  def tear_down_temp_tables
    DB.open do |db|
      db.drop_table? :udf_mig_tc_to_extid
    end
  end


end


class InstanceKey < Struct.new(:resource_id, :resource_component_id, :barcode, :indicator)

  def self.from_row(row)

    if row[:barcode].nil? && row[:container1AlphaNumIndicator].nil? && row[:container1NumericIndicator].nil?
      # This cannot be matched to a TopContainer
      return nil
    end

    barcode = stringify(row[:barcode])

    if barcode
      indicator = nil
    elsif (indicator = stringify(row[:container1AlphaNumIndicator]))
    else
      indicator = sprintf("%g", row[:container1NumericIndicator])
    end

    new(row[:resourceId], row[:resourceComponentId], barcode, indicator)
  end


  def initialize(resource_id, resource_component_id, barcode, indicator)
    super(self.class.stringify(resource_id),
          self.class.stringify(resource_component_id),
          self.class.stringify(barcode),
          self.class.stringify(indicator))
  end


  def self.stringify(value)
    if value == "" || value.nil?
      nil
    else
      value.to_s
    end
  end

  def to_bytes
    Digest::SHA1.digest(self.to_json)
  end


  def valid?
    barcode || indicator
  end

end


class InstanceData < Struct.new(:voyager_info, :box_type, :restricted, :exported_to_voyager)

  UNKNOWN_DIMENSION = '99999999'

  include JSONModel

  def self.from_row(row)
    new(row[:userDefinedString1], row[:userDefinedString2],
        row[:userDefinedBoolean1], row[:userDefinedBoolean2])
  end


  def voyager_bib_id
    if voyager_info && !voyager_info.empty?
      self[:voyager_info].split("_")[0]
    end
  end

  def voyager_holding_id
    if voyager_info && !voyager_info.empty?
      self[:voyager_info].split("_")[1]
    end
  end

  def container_profile
    if !box_type || box_type.empty?
      return nil
    end

    profile = ContainerProfile[:name => box_type]

    if !profile
      profile = ContainerProfile.create_from_json(JSONModel(:container_profile).from_hash('name' => box_type,
                                                                                          'dimension_units' => 'inches',
                                                                                          'extent_dimension' => 'width',
                                                                                          'height' => UNKNOWN_DIMENSION,
                                                                                          'width' => UNKNOWN_DIMENSION,
                                                                                          'depth' => UNKNOWN_DIMENSION))
    end

    profile
  end


  def empty?
    voyager_info.empty? && box_type.empty? && restricted.nil? && exported_to_voyager.nil?
  end

end



class ArchivistsToolkit

  def initialize(db)
    @db = db

    @key_set = {}
    @value_set = {}
    @missing_user_defined_fields = {}

    preload_instances
  end


  def find_matching_containers(column, record_ids, top_container)
    record_ids.map do |record_id|

      if column == :resourceId
        resource_id = record_id
        resource_component_id = nil
      elsif :resourceComponentId
        resource_id = nil
        resource_component_id = record_id
      else
        raise "Unrecognized column: #{column}"
      end

      if top_container.barcode
        barcode = top_container.barcode
        indicator = nil
      else
        barcode = nil
        indicator = top_container.indicator
      end

      search_key = InstanceKey.new(resource_id, resource_component_id, barcode, indicator)
      search_key_bytes = search_key.to_bytes

      value = @key_set[search_key_bytes]
      if value
        @value_set[value]
      elsif @missing_user_defined_fields[search_key_bytes]
        :no_data # No problem here.  There was just no data to load.
      else
        Log.debug("Not found: #{search_key.inspect}")
        nil
      end

    end.compact.uniq
  end


  private


  def preload_instances
    count = 0

    id_set = @db[:ArchDescriptionInstances].select(:archDescriptionInstancesId).map {|row| row[:archDescriptionInstancesId]}
    id_set.each_slice(1000) do |ids|
      @db[:ArchDescriptionInstances].filter(:archDescriptionInstancesId => ids).each do |row|
        count += 1

        if (count % 100000) == 0
          Log.info("Preloaded #{count} containers...")
        end

        key = InstanceKey.from_row(row)

        next if !key # a digital object instance (or something else we don't care about)

        if !key.valid?
          Log.warn("Something is banana cakes: #{key.inspect} -- #{row.inspect}")
          next
        end

        data = InstanceData.from_row(row)

        # Switch to a more compact byte representation to save memory
        key_bytes = key.to_bytes

        if data.empty?
          @missing_user_defined_fields[key_bytes] = true
        else
          if (@key_set[key_bytes] && @key_set[key_bytes] != data.hash)
            Log.error("DATA MISMATCH: #{key.inspect}: #{row.inspect}")
          end

          @key_set[key_bytes] = data.hash
          @value_set[data.hash] = data
        end
      end
    end

  end


end
