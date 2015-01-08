require_relative "../common"

$backend_port = TestUtils::free_port_from(3636)
$frontend_port = TestUtils::free_port_from(4545)
$solr_port = TestUtils::free_port_from(2989)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"
$expire = 300

# for the indexers
AppConfig[:solr_url] = "http://localhost:#{$solr_port}"

$backend_start_fn = proc {
  TestUtils::start_backend($backend_port,
                           {
                             :frontend_url => $frontend,
                             :solr_port => $solr_port,
                             :session_expire_after_seconds => $expire,
                             :realtime_index_backlog_ms => 600000
                           })
}

$frontend_start_fn = proc {
  TestUtils::start_frontend($frontend_port, $backend)
}
