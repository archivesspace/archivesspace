require_relative 'relationships'

# This extends regular relationships to add support for storing a relationship
# between two records where the direction of the relationship matters.  For
# example, a relationship between two agents might be called "is_parent_of" when
# viewed from one side, and "is_child_of" when viewed from the other.
#
# Directional relationships are just relationships with some extra
# characteristics:
#
#  * In the database, we store 'relationship_target_record_type' and
#    'relationship_target_id'.  These contain the type and identifier of the
#    record that is the subject of this relationship.  If the relationship is:
#
#     A is_parent_of B
#
#    Then these two columns will contain a reference to record B.  This
#    information is used to store the direction of the relationship.
#
#  * We also store 'jsonmodel_type' in the database for the relationship, since
#    there can be multiple relationship record types corresponding to a single
#    logical relationship (the related_agent relationship uses this feature)
#
#  * The 'relator' property describes the nature of the relationship.  This
#    should be an enum containing either one or two values.  If it's one value,
#    the relator will be the same whether you look at the relationship from
#    record A or record B (a relator like "sibling" would make sense for this
#    case).
#
#    If there are two relator values, they should be logical inverses.  If you
#    fetch record A you might see a relator of "is_parent_of" for its
#    relationship.  Fetch record B and the same relationship might show a
#    relator of "is_child_of"--the relator is automatically mapped based on which
#    direction you're traversing the relationship in.

module DirectionalRelationships

  def self.included(base)
    base.include(Relationships)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.prepare_directional_relationship_for_storage(json)
    super
  end


  module ClassMethods

    attr_reader :directional_relationships

    def define_directional_relationship(opts)
      self.define_relationship(opts)
      @directional_relationships ||= []
      @directional_relationships << opts
    end


    def prepare_directional_relationship_for_storage(json)
      Array(directional_relationships).each do |rel|
        property = rel[:json_property]

        ASUtils.wrap(json[property]).each do |relationship|
          # Relationships are directionless by default, but here we want to
          # store a direction (e.g. A is a child of B)
          #
          # Store the JSONModel type and ID
          #
          ref = JSONModel.parse_reference(relationship['ref'])
          relationship['relationship_target_record_type'] = ref[:type]
          relationship['relationship_target_id'] = ref[:id].to_i
        end
      end
    end


    def prepare_directional_relationship_for_display(json)
      Array(directional_relationships).each do |rel|
        property = rel[:json_property]

        ASUtils.wrap(json[property]).each do |relationship|
          ref = JSONModel.parse_reference(json.uri)

          if (relationship['relationship_target_record_type'] == ref[:type] &&
              relationship['relationship_target_id'] == ref[:id].to_i)
            # This means we're looking at the relationship from the other side.
            #
            # For example, if the relationship is "A is a parent of B", then we
            # want:
            #
            #   * 'GET A' to yield  {relator => 'is_parent_of', ref => 'B'}
            #   * 'GET B' to yield  {relator => 'is_child_of', ref => 'A'}
            #
            # So we want to invert the relator for this case.

            relator_values = JSONModel.enum_values(JSONModel(relationship['jsonmodel_type'].intern).schema['properties']['relator']['dynamic_enum'])
            relator_values -= ['other_unmapped'] # grumble.

            if relator_values.length == 2
              # When there are two possible values we assume they're inverses
              # Set the relator to whatever the inverse of the current one is.
              relationship['relator'] = (relator_values - [relationship['relator']]).first
            end
          end
        end
      end
    end



    def create_from_json(json, opts = {})
      prepare_directional_relationship_for_storage(json)
      super
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        prepare_directional_relationship_for_display(json)
      end

      jsons
    end

  end


end
