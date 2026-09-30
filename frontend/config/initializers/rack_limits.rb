# Record forms in the tree are saved as multipart/form-data, where every field is
# a part, so records with thousands of linked records exceed Rack's default limit.
Rack::Utils.multipart_total_part_limit = AppConfig[:frontend_multipart_total_part_limit]
