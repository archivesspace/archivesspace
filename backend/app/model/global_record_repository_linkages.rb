# Naming is hard.
#
# The public interface needs to know which subject/agent/(other?) records are
# used within which repositories.  That's a slightly awkward question to answer,
# because in the ArchivesSpace data model, subjects and agents are "global", and
# don't belong to any particular repository.
#
# So, this class can take a global record type (like an Agent or Subject), a
# relationship of interest (like `:subject`), and list of records of that type,
# then traverse the relationship to work out which agents/subjects are used in
# each repository.
#

require 'set'

class GlobalRecordRepositoryLinkages

  def initialize(global_record_model, relationship)
    @global_record_model = global_record_model
    @relationship = @global_record_model.find_relationship(relationship)

    if @global_record_model.model_scope != :global
      raise "#{self} only works with global model types"
    end
  end

  # Return a hash like:
  #
  # {#<record obj> => [#<repo1>, #<repo2>], ...}
  #
  def call(records)
    record_id_to_repo_ids = build_id_map(records)

    repositories = Repository.all.group_by(&:id)

    result = {}
    records.each do |record|
      result[record] = record_id_to_repo_ids
                       .fetch(record.id, [])
                       .map {|repo_ids| repositories.fetch(repo_ids)}
                       .flatten
    end

    result
  end

  private

  # Build a map from record IDs to the repositories that use them
  #
  # For example: {subject.id => [repo1.id, repo2.id, ...], subject2.id => [...], ...}
  #
  def build_id_map(records)
    result = {}

    # E.g. subject_rlshp.subject_id
    global_model_column = @relationship.reference_columns_for(@global_record_model).first

    @relationship.participating_models.each do |linked_repo_model|
      # We're only interested in record types that belong to a repo
      next unless linked_repo_model.model_scope == :repository

      # Since we're only working with relationships that link a global record to
      # a repo-scoped record, we don't have to worry about relationships between
      # records of the same type, so there'll only ever be one column to check.
      linked_repo_model_column = @relationship.reference_columns_for(linked_repo_model).first

      # E.g. join archival_object to subject_rlshp
      ds = linked_repo_model
           .any_repo
           .join(@relationship.table_name,
                 linked_repo_model_column => Sequel.qualify(linked_repo_model.table_name, :id))

      # Limit to the objects we care about and map out the linkages from our
      # records to the repositories that use them.
      ds.filter(global_model_column => records.map(&:id))
        .select(global_model_column, Sequel.qualify(linked_repo_model.table_name, :repo_id))
        .distinct
        .each do |row|
        global_record_id = row[global_model_column]
        repo_id = row[:repo_id]

        result[global_record_id] ||= Set.new
        result[global_record_id] << repo_id
      end
    end

    result
  end
end
