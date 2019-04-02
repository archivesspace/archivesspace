unless ['5.0.1', '5.0.7.2'].include?(Rails.version)

  $stderr.puts "

Hello!

You're seeing this message because the file
'frontend/config/initializers/rails_route_concurrency_fix.rb' has been loaded in
a version of Rails we never tested it on.

This file addresses the following concurrency bug:

  https://github.com/rails/rails/issues/33026

But it should have been fixed in newer versions of Rails, as long as you're on
5.2 or greater.  If so, please delete this file!

"

  raise "Rails version issue: rails_route_concurrency_fix.rb"
end


class ActionDispatch::Journey::Path::Pattern
  def eager_load!
    required_names
    offsets
    to_regexp
    nil
  end
end

class ActionDispatch::Journey::Route
  def eager_load!
    path.eager_load!
    ast
    parts
    required_defaults
    nil
  end
end

class ActionDispatch::Journey::Router
  def eager_load!
    # Eagerly trigger the simulator's initialization so
    # it doesn't happen during a request cycle.
    simulator
    nil
  end
end

class ActionDispatch::Routing::RouteSet
  def eager_load!
    router.eager_load!
    routes.each(&:eager_load!)
    nil
  end
end

class Rails::Application::RoutesReloader

  def finalize!
    route_sets.each(&:finalize!)
    route_sets.each(&:eager_load!)
  end

end
