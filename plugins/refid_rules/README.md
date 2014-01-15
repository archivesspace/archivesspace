
# refid_rules plug-in

This plug-in allows you to override the default auto-generator for component ref_ids.

The new ref_id generator is defined in the application configuration as an ERB template under the key :refid_rule, for example:

    AppConfig[:refid_rule] = "<%= repository['repo_code'] %>_<%= resource['formatted_id']  %>_<%= SecureRandom.hex %>"

Three JSONModel objects are available in the template:

    component - the resource component for which the ref_id is being generated
    resource - the resource to which the component belongs
    repository - the repository to which the resource belongs

Note that the usual validation rules apply for the generated ref_id. For example it must not contain spaces. Be sure to test your rule before releasing it.

If AppConfig[:refid_rule] is not specified then the default auto-generator will be used.
