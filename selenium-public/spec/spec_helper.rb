require_relative "../../selenium/common"

$backend_port = TestUtils::free_port_from(3636)
$public_port = TestUtils::free_port_from(4546)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$public_port}"
$expire = 300

$backend_start_fn = proc {
  TestUtils::start_backend($backend_port,
                           {
                             :frontend_url => $frontend,
                             :session_expire_after_seconds => $expire
                           })
}

$frontend_start_fn = proc {
  TestUtils::start_public($public_port, $backend)
}
