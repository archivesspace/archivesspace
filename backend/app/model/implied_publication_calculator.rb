#
# All of the for_* methods in this class take an array of Sequel model objects
# and return a hash indicating whether each object can be considered to be
# published by implication.
#
# For example, you give it:
#
#  [subject1, subject2, subject3]
#
# and it returns:
#
#  {
#    subject1 => true,
#    subject2 => false,
#    subject3 => false
#  }
#
# meaning that subject1 was linked to at least one published record, while
# subjects 2 and 3 were not (maybe they're not linked to anything, or maybe only
# to unpublished/suppressed records).

class ImpliedPublicationCalculator

  # A top container is published if it's linked (via an instance ->
  # sub_container) to at least one published record
  def for_top_containers(top_containers)
    top_containers_by_id = Hash[top_containers.map {|top_container| [top_container.id, top_container]}]
    result = Hash[top_containers.map {|top_container| [top_container, false]}]

    Instance.enclosing_associations.each do |association|
      model = association[:model]
      model_table = model.table_name

      top_container_link = SubContainer.find_relationship(:top_container_link)

      # Join our (e.g.) Accession to an Instance, then Instance to SubContainer,
      # then SubContainer to TopContainer.
      joined_ds = model
                    .join(:instance, association[:key] => Sequel.qualify(model_table, :id))
                    .join(:sub_container, :instance_id => Sequel.qualify(:instance, :id))
                    .join(top_container_link.table_name, :sub_container_id => Sequel.qualify(:sub_container, :id))
                    .join(:top_container, Sequel.qualify(:top_container, :id) => Sequel.qualify(top_container_link.table_name, :top_container_id))
                    .filter(Sequel.qualify(:top_container, :id) => top_containers_by_id.keys)

      linked_records = if model.included_modules.include?(TreeNodes)
                         for_tree_nodes(joined_ds
                                          .select(Sequel.qualify(model_table, :id),
                                                  Sequel.qualify(model_table, :parent_id),
                                                  Sequel.qualify(model_table, :root_record_id),
                                                  Sequel.qualify(model_table, :publish),
                                                  Sequel.qualify(model_table, :suppressed),
                                                  Sequel.as(Sequel.qualify(model_table, :repo_id),
                                                            :repository_id),
                                                  Sequel.as(Sequel.qualify(:top_container, :id),
                                                            :top_container_id))
                                          .all)
                       else
                         for_top_level_records(joined_ds
                                                 .select(Sequel.qualify(model_table, :id),
                                                         Sequel.qualify(model_table, :publish),
                                                         Sequel.qualify(model_table, :suppressed),
                                                         Sequel.as(Sequel.qualify(model_table, :repo_id),
                                                                   :repository_id),
                                                         Sequel.as(Sequel.qualify(:top_container, :id),
                                                                   :top_container_id))
                                                 .all)
                       end

      linked_records.each do |linked_record, published|
        if published
          result[top_containers_by_id.fetch(linked_record[:top_container_id])] = published
        end
      end
    end

    result
  end

  # An agent is published if it's linked to at least one archival record that's
  # published.
  def for_agents(agents)
    return {} if agents.empty?
    assert_same_type!(agents)

    agent_model = agents[0].class
    result = Hash[agents.map {|node| [node, false]}]
    agents_by_id = Hash[agents.map {|agent| [agent.id, agent]}]

    agent_model.relationship_dependencies[:linked_agents].each do |model|

      # Things like events aren't publishable and shouldn't count for these calculations
      next unless model.included_modules.include?(Publishable)

      link_relationship = model.find_relationship(:linked_agents)

      # agent_person_rlshp
      link_table = link_relationship.table_name

      link_relationship.reference_columns_for(model).each do |model_link_column|
        link_relationship.reference_columns_for(agent_model).each do |agent_link_column|
          linked_records = model
                             .join(link_table,
                                   Sequel.qualify(link_table, model_link_column) => Sequel.qualify(model.table_name, :id))
                             .filter(Sequel.qualify(link_table, agent_link_column) => agents_by_id.keys)
                             .select(Sequel.qualify(model.table_name, :id),
                                     Sequel.qualify(model.table_name, :publish),
                                     Sequel.qualify(model.table_name, :suppressed),
                                     Sequel.as(Sequel.qualify(link_table, agent_link_column),
                                               :agent_id))

          if model.columns.include?(:repo_id)
            linked_records = linked_records
                               .select_append(Sequel.as(Sequel.qualify(model.table_name, :repo_id),
                                                        :repository_id))
          end

          published_status = if model.included_modules.include?(TreeNodes)
                               for_tree_nodes(linked_records
                                                .select_append(Sequel.qualify(model.table_name, :parent_id),
                                                               Sequel.qualify(model.table_name, :root_record_id))
                                                .all)
                             else
                               for_top_level_records(linked_records.all)
                             end

          published_status.each do |linked_record, published|
            if published
              result[agents_by_id.fetch(linked_record[:agent_id])] = true
            end
          end
        end
      end
    end

    result
  end

  # An subject is published if it's linked to at least one archival record that's
  # published.
  def for_subjects(subjects)
    result = Hash[subjects.map {|node| [node, false]}]
    subjects_by_id = Hash[subjects.map {|subject| [subject.id, subject]}]

    Subject.relationship_dependencies[:subject].each do |model|
      link_relationship = model.find_relationship(:subject)

      # subject_rlshp
      link_table = link_relationship.table_name

      link_relationship.reference_columns_for(model).each do |model_link_column|
        link_relationship.reference_columns_for(Subject).each do |subject_link_column|
          # Join subject_rlshp to (e.g.) accession
          linked_records = model
                             .join(link_table,
                                   Sequel.qualify(link_table, model_link_column) => Sequel.qualify(model.table_name, :id))
                             .filter(Sequel.qualify(link_table, subject_link_column) => subjects_by_id.keys)
                             .select(Sequel.qualify(model.table_name, :id),
                                     Sequel.qualify(model.table_name, :publish),
                                     Sequel.qualify(model.table_name, :suppressed),
                                     Sequel.as(Sequel.qualify(link_table, subject_link_column),
                                               :subject_id))

          if model.columns.include?(:repo_id)
            linked_records = linked_records
                               .select_append(Sequel.as(Sequel.qualify(model.table_name, :repo_id),
                                                        :repository_id))
          end

          published_status = if model.included_modules.include?(TreeNodes)
                               for_tree_nodes(linked_records
                                                          .select_append(Sequel.qualify(model.table_name, :parent_id),
                                                                         Sequel.qualify(model.table_name, :root_record_id))
                                                          .all)
                             else
                               for_top_level_records(linked_records.all)
                             end

          published_status.each do |linked_record, published|
            if published
              result[subjects_by_id.fetch(linked_record[:subject_id])] = true
            end
          end
        end
      end
    end

    result
  end

  private

  # An tree node (like an Archival Object) is published if it's marked as
  # published and none of its ancestors are unpublished (including the root
  # record).
  def for_tree_nodes(tree_nodes, check_root_record = true)
    return {} if tree_nodes.empty?
    assert_same_type!(tree_nodes)

    # E.g. ArchivalObject
    node_model = tree_nodes[0].class.node_model

    # E.g. Resource
    root_model = tree_nodes[0].class.root_model

    # Initialize our result map to true -- assuming "published" by default.
    result = Hash[tree_nodes.map {|node| [node, true]}]

    if check_root_record
      # If we're the top-level call, we'll check the repository and root
      # record's publication status.  There's no point doing this at every
      # level of the tree, but do it up front to save some potential work.
      root_record_id_to_child = {}
      tree_nodes.each do |node|
        if repository_published?(node[:repository_id])
          root_record_id_to_child[node.root_record_id] ||= []
          root_record_id_to_child[node.root_record_id] << node
        else
          result[node] = false
        end
      end

      return result if root_record_id_to_child.empty?

      root_model
        .filter(:id => root_record_id_to_child.keys)
        .filter(Sequel.|({:publish => 0},
                         {:suppressed => 1}))
        .select(:id)
        .each do |root_record|
        root_record_id_to_child.fetch(root_record.id).each do |node|
          result[node] = false
        end
      end
    end

    parent_id_to_child = {}
    tree_nodes.each do |node|
      if result[node] && node.publish == 1 && node.suppressed == 0
        # OK so far, but check the ancestors.
        if node.parent_id
          parent_id_to_child[node.parent_id] ||= []
          parent_id_to_child[node.parent_id] << node
        end
      else
        # Unpublished/suppressed.  Nothing more to check.
        result[node] = false
      end
    end

    unless parent_id_to_child.empty?
      parent_ids = parent_id_to_child.keys
      parent_publication_status = for_tree_nodes(node_model.filter(:id => parent_ids)
                                                   .select(:id, :parent_id, :root_record_id, :publish, :suppressed)
                                                   .all,
                                                 false)

      parent_publication_status.each do |parent, published|
        # If the parent was unpublished, that overrides our previous result.
        parent_id_to_child.fetch(parent.id).each do |node|
          result[node] &&= published
        end
      end
    end

    result
  end

  # A top-level record is published as long as it's `published` flag is set, and
  # it's not suppressed.
  def for_top_level_records(records)
    result = {}

    records.each do |record|
      result[record] = repository_published?(record[:repository_id]) && record.publish == 1 && record.suppressed == 0
    end

    result
  end

  def assert_same_type!(records)
    unless records.map(&:class).uniq.length == 1
      raise "All records must be of the same type!"
    end
  end

  def repository_published?(repo_id)
    return true if repo_id.nil?

    @repository_published_status ||= {}
    @repository_published_status[repo_id] ||= (Repository[repo_id].publish == 1)
    @repository_published_status[repo_id]
  end
end
