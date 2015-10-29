# module Less
#   module Rails
#     module Helpers
#       module ClassMethods
#         def asset_url(asset)
#           puts "ASSET #{asset}"
#           public_path = if scope.respond_to?(:asset_paths)
#                           scope.asset_paths.compute_public_path asset, ::Rails.application.config.assets.prefix
#                         else
#                           scope.path_to_asset(asset)
#                         end

#           "url(#{public_path})"
#         end
#       end
#     end
#   end
# end
