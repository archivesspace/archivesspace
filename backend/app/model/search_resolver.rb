class SearchResolver

  # Theoretically someone might resolve a field that matches an unbounded number
  # of records, and this could cause an OOM.  Set an upper bound.
  MAX_RESOLVE_RESULTS = AppConfig[:max_page_size] * 2

  def initialize(resolve_definitions)
    @resolve_definitions = resolve_definitions.map {|s| ResolveDefinition.parse(s)}
  end

  def resolve(results)
    @resolve_definitions.each do |resolve_def|
      source_field = resolve_def.source_field
      target_field = resolve_def.target_field
      custom_resolver = resolve_def.custom_resolver

      # Build up and run a Solr query to pull back the documents we'll be inlining
      search_terms = results['results'].map {|doc| doc[source_field]}.compact.flatten

      unless search_terms.empty?
        boolean_query = JSONModel.JSONModel(:boolean_query)
                        .from_hash('op' => 'OR',
                                   'subqueries' => search_terms.map {|term|
                                     JSONModel.JSONModel(:field_query)
                                       .from_hash('field' => target_field,
                                                  'value' => term,
                                                  'literal' => true)
                                       .to_hash
                                   })

        query = JSONModel.JSONModel(:advanced_query).from_hash('query' => boolean_query)

        resolved_results = Solr.search(Solr::Query.create_advanced_search(query).pagination(1, MAX_RESOLVE_RESULTS))

        if resolved_results['total_hits'] > MAX_RESOLVE_RESULTS
          Log.warn("Resolve query hit MAX_RESOLVE_RESULTS.  Result set may be incomplete: #{query.to_hash.inspect}")
        end

        # Insert the resolved records into our original result set.
        results['results'].each do |result|
          resolved = resolved_results['results'].map {|resolved|
            key = resolved[target_field]
            if ASUtils.wrap(result[source_field]).include?(key)
              {key => [SearchResolver.resolver_for(custom_resolver).resolve(resolved)]}
            end
          }.compact

          # Merge our entries into a single hash keyed on `key`
          result["_resolved_#{source_field}"] = resolved.reduce {|merged, elt| merged.merge(elt) {|key, coll1, coll2| coll1 + coll2}}
        end
      end
    end
  end

  ResolveDefinition = Struct.new(:source_field, :target_field, :custom_resolver) do
    def self.parse(resolve_def)
      (source_field, target_field, custom_resolver) = resolve_def.split(/[:@]/)

      unless source_field && target_field
        raise "Resolve request parameter not well-formed: #{resolve_def}.  Should be source_field:target_field"
      end

      new(source_field, target_field, custom_resolver)
    end
  end

  def self.add_custom_resolver(name, resolver_class)
    @custom_resolvers ||= {}
    @custom_resolvers[name] = resolver_class
  end

  def self.resolver_for(name)
    if name
      clz = @custom_resolvers.fetch(name) {
        raise "Unrecognized search resolver: #{name}"
      }

      clz.new
    else
      PassThroughResolver.new
    end
  end

  class PassThroughResolver
    def resolve(record)
      record
    end
  end

end
