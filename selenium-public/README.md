# Selenium test suite for public interface

See `selenium/README.md` for information on running the Selenium
tests.  The commands are the same for the public interface, except we
use:

     selenium:public:test

in place of

     selenium:test

and 

     ASPACE_FRONTEND_URL

should be set to the url for the public application (when the tests are not
running in standalone mode).

